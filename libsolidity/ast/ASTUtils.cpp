/*
	This file is part of solidity.

	solidity is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	solidity is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with solidity.  If not, see <http://www.gnu.org/licenses/>.
*/
// SPDX-License-Identifier: GPL-3.0

#include <libsolidity/analysis/ConstantEvaluator.h>
#include <libsolidity/ast/AST.h>
#include <libsolidity/ast/ASTUtils.h>
#include <libsolidity/ast/ASTVisitor.h>

#include <libsolutil/Algorithms.h>

#include <algorithm>
#include <set>
#include <vector>

namespace solidity::frontend
{

ASTNode const* locateInnermostASTNode(int _offsetInFile, SourceUnit const& _sourceUnit)
{
	ASTNode const* innermostMatch = nullptr;
	auto locator = SimpleASTVisitor(
		[&](ASTNode const& _node) -> bool
		{
			// In the AST parent location always covers the whole child location.
			// The parent is visited first so to get the innermost node we simply
			// take the last one that still contains the offset.

			if (!_node.location().containsOffset(_offsetInFile))
				return false;

			innermostMatch = &_node;
			return true;
		},
		[](ASTNode const&) {}
	);
	_sourceUnit.accept(locator);
	return innermostMatch;
}

bool isConstantVariableRecursive(VariableDeclaration const& _varDecl)
{
	solAssert(_varDecl.isConstant(), "Constant variable expected");

	auto visitor = [](VariableDeclaration const& _variable, util::CycleDetector<VariableDeclaration>& _cycleDetector, size_t _depth)
	{
		solAssert(_depth < 256, "Recursion depth limit reached");
		if (!_variable.value())
			// This should result in an error later on.
			return;

		if (auto referencedVarDecl = dynamic_cast<VariableDeclaration const*>(
			ASTNode::referencedDeclaration(*_variable.value()))
		)
			if (referencedVarDecl->isConstant())
				_cycleDetector.run(*referencedVarDecl);
	};

	return util::CycleDetector<VariableDeclaration>(visitor).run(_varDecl) != nullptr;
}

VariableDeclaration const* rootConstVariableDeclaration(VariableDeclaration const& _varDecl)
{
	solAssert(_varDecl.isConstant(), "Constant variable expected");
	solAssert(!isConstantVariableRecursive(_varDecl), "Recursive declaration");

	VariableDeclaration const* rootDecl = &_varDecl;
	Identifier const* identifier;
	while ((identifier = dynamic_cast<Identifier const*>(rootDecl->value().get())))
	{
		auto referencedVarDecl = dynamic_cast<VariableDeclaration const*>(identifier->annotation().referencedDeclaration);
		if (!referencedVarDecl || !referencedVarDecl->isConstant())
			return nullptr;
		rootDecl = referencedVarDecl;
	}
	return rootDecl;
}

Expression const* resolveOuterUnaryTuples(Expression const* _expr)
{
	while (auto const* tupleExpression = dynamic_cast<TupleExpression const*>(_expr))
		if (tupleExpression->components().size() == 1)
			_expr = tupleExpression->components().front().get();
		else
			break;
	return _expr;
}

Type const* type(Expression const& _expression)
{
	solAssert(!!_expression.annotation().type, "Type requested but not present.");
	return _expression.annotation().type;
}

Type const* type(VariableDeclaration const& _variable)
{
	solAssert(!!_variable.annotation().type, "Type requested but not present.");
	return _variable.annotation().type;
}

bigint contractStorageSizeUpperBound(ContractDefinition const& _contract, VariableDeclaration::Location _location)
{
	solAssert(_location == VariableDeclaration::Location::Unspecified || _location == VariableDeclaration::Location::Transient);

	bigint size = 0;
	for (ContractDefinition const* contract: _contract.annotation().linearizedBaseContracts)
		for (VariableDeclaration const* variable: contract->stateVariables())
			if (
				!(variable->isConstant() || variable->immutable()) &&
				variable->referenceLocation() == _location
			)
				size += variable->annotation().type->storageSizeUpperBound();

	return size;
}

u256 layoutBaseForInheritanceHierarchy(ContractDefinition const& _topLevelContract, DataLocation _location)
{
	if (_location != DataLocation::Storage)
	{
		solAssert(_location == DataLocation::Transient);
		return 0;
	}

	if (auto const* storageLayoutSpecifier = _topLevelContract.storageLayoutSpecifier())
		return *storageLayoutSpecifier->annotation().baseSlot;

	return 0;
}

std::optional<u256> erc7201CompileTimeValue(FunctionCall const& _erc7201Call)
{
	auto const* erc7201Function = dynamic_cast<MagicVariableDeclaration const*>(ASTNode::referencedDeclaration(_erc7201Call.expression()));
	solAssert(erc7201Function);
	solAssert(erc7201Function->functionType(true /* internal */)->kind() == FunctionType::Kind::ERC7201);

	auto evaluatedResult = ConstantEvaluator::tryEvaluate(_erc7201Call);

	if (evaluatedResult.isEmpty())
		return std::nullopt;

	solAssert(evaluatedResult.isRational());
	auto rationalValue = evaluatedResult.asRational();
	solAssert(rationalValue.denominator() == 1);
	bigint baseSlot = rationalValue.numerator();
	solAssert(baseSlot <= std::numeric_limits<u256>::max());
	return u256(baseSlot);
}

namespace
{

bigint storageSlotCountImpl(
	Type const& _type,
	bool _storageLayoutV2,
	std::set<StructDefinition const*>& _stack
);

/// Same packing as StorageOffsets::computeOffsets, but the total may exceed 2**256.
bigint packedStorageSlotCount(
	std::vector<Type const*> const& _types,
	bool _storageLayoutV2,
	std::set<StructDefinition const*>& _stack
)
{
	bigint slotOffset = 0;
	unsigned byteOffset = 0;
	for (Type const* type: _types)
	{
		solAssert(type, "");
		solAssert(type->canBeStored(), "");
		solAssert(type->storageBytes() <= 32, "");
		unsigned const bytes = type->storageBytes();
		if (byteOffset + bytes > 32)
		{
			++slotOffset;
			byteOffset = 0;
		}
		bigint const size = storageSlotCountImpl(*type, _storageLayoutV2, _stack);
		solAssert(size >= 1, "");
		if (size == 1 && byteOffset + bytes <= 32)
			byteOffset += bytes;
		else
		{
			slotOffset += size;
			byteOffset = 0;
		}
	}
	if (byteOffset > 0)
		++slotOffset;
	return slotOffset;
}

bigint storageSlotCountImpl(
	Type const& _type,
	bool _storageLayoutV2,
	std::set<StructDefinition const*>& _stack
)
{
	if (auto const* mappingType = dynamic_cast<MappingType const*>(&_type))
	{
		if (!_storageLayoutV2)
			return 1;
		// Nested mappings are flattened: the whole chain reserves one 2**160 range,
		// sized by the first value that is not itself a mapping.
		Type const* value = mappingType->valueType();
		solAssert(value, "");
		while (auto const* inner = dynamic_cast<MappingType const*>(value))
			value = inner->valueType();
		bigint const valueSlots = storageSlotCountImpl(*value, true, _stack);
		solAssert(valueSlots >= 1, "");
		return (bigint(1) << 160) * valueSlots;
	}
	if (auto const* arrayType = dynamic_cast<ArrayType const*>(&_type))
	{
		if (arrayType->isDynamicallySized())
			return 1;
		unsigned const baseBytes = arrayType->baseType()->storageBytes();
		if (baseBytes == 0)
			return 1;
		if (baseBytes < 32)
		{
			unsigned const itemsPerSlot = 32 / baseBytes;
			bigint const size = (bigint(arrayType->length()) + (itemsPerSlot - 1)) / itemsPerSlot;
			return size < 1 ? bigint(1) : size;
		}
		bigint const baseSlots = storageSlotCountImpl(
			*arrayType->baseType(),
			_storageLayoutV2,
			_stack
		);
		bigint const size = bigint(arrayType->length()) * baseSlots;
		return size < 1 ? bigint(1) : size;
	}
	if (auto const* structType = dynamic_cast<StructType const*>(&_type))
	{
		if (!_stack.insert(&structType->structDefinition()).second)
			return bigint(1) << 256;
		std::vector<Type const*> members;
		for (auto const& member: structType->members(nullptr))
			members.push_back(member.type);
		bigint const size = packedStorageSlotCount(members, _storageLayoutV2, _stack);
		_stack.erase(&structType->structDefinition());
		return size < 1 ? bigint(1) : size;
	}
	return 1;
}

}

thread_local bool StorageLayoutScope::s_active = false;

StorageLayoutScope::StorageLayoutScope(bool _enabled):
	m_previous(s_active)
{
	s_active = _enabled;
}

StorageLayoutScope::~StorageLayoutScope()
{
	s_active = m_previous;
}

bool StorageLayoutScope::active()
{
	return s_active;
}

bigint storageSlotCount(Type const& _type, bool _storageLayoutV2)
{
	std::set<StructDefinition const*> stack;
	return storageSlotCountImpl(_type, _storageLayoutV2, stack);
}

bigint contractStorageSize(ContractDefinition const& _contract, bool _storageLayoutV2)
{
	std::vector<Type const*> types;
	auto const& bases = _contract.annotation().linearizedBaseContracts;
	for (auto base = bases.rbegin(); base != bases.rend(); ++base)
		for (VariableDeclaration const* variable: (*base)->stateVariables())
			if (
				!(variable->isConstant() || variable->immutable()) &&
				variable->referenceLocation() == VariableDeclaration::Location::Unspecified
			)
			{
				solAssert(variable->annotation().type, "");
				types.push_back(variable->annotation().type);
			}
	std::set<StructDefinition const*> stack;
	return packedStorageSlotCount(types, _storageLayoutV2, stack);
}

namespace
{

bool isRawMappingSlot(Expression const& _expression)
{
	if (auto const* identifier = dynamic_cast<Identifier const*>(&_expression))
	{
		auto const* variable = dynamic_cast<VariableDeclaration const*>(
			identifier->annotation().referencedDeclaration
		);
		if (
			!variable ||
			!variable->isStateVariable() ||
			variable->isConstant() ||
			variable->immutable() ||
			variable->referenceLocation() != VariableDeclaration::Location::Unspecified
		)
			return false;
		Type const* variableType = type(*variable);
		return variableType && variableType->category() == Type::Category::Mapping;
	}
	if (auto const* member = dynamic_cast<MemberAccess const*>(&_expression))
	{
		auto const* structType = dynamic_cast<StructType const*>(type(member->expression()));
		if (!structType || structType->location() != DataLocation::Storage)
			return false;
		Type const* memberType = structType->memberType(member->memberName());
		return memberType && memberType->category() == Type::Category::Mapping;
	}
	return false;
}

}

std::optional<DirectStorageMappingIndex> directStorageMappingIndex(IndexAccess const& _index)
{
	if (!StorageLayoutScope::active())
		return std::nullopt;
	Type const* resultType = type(_index);
	if (!resultType || resultType->category() == Type::Category::Mapping)
		return std::nullopt;

	std::vector<Expression const*> keys;
	Expression const* current = &_index;
	while (auto const* access = dynamic_cast<IndexAccess const*>(current))
	{
		Type const* baseType = type(access->baseExpression());
		if (!baseType || baseType->category() != Type::Category::Mapping)
			break;
		if (!access->indexExpression())
			return std::nullopt;
		keys.push_back(access->indexExpression());
		current = &access->baseExpression();
	}
	current = resolveOuterUnaryTuples(current);
	if (!current || keys.empty() || !isRawMappingSlot(*current))
		return std::nullopt;
	std::reverse(keys.begin(), keys.end());
	return DirectStorageMappingIndex{current, std::move(keys)};
}

}
