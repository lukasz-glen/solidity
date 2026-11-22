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

#pragma once

#include <libsolutil/Numeric.h>

#include <optional>
#include <vector>

namespace solidity::frontend
{

class ASTNode;
class ContractDefinition;
class Declaration;
class Expression;
class FunctionCall;
class IndexAccess;
class SourceUnit;
class Type;
class VariableDeclaration;

/// Selects the storage layout used by Type::storageSize() and struct member offsets.
/// Experimental StorageLayoutV2 reserves a slot range for every mapping.
class StorageLayoutScope
{
public:
	explicit StorageLayoutScope(bool _enabled);
	~StorageLayoutScope();
	StorageLayoutScope(StorageLayoutScope const&) = delete;
	StorageLayoutScope& operator=(StorageLayoutScope const&) = delete;

	static bool active();

private:
	bool m_previous = false;
	static thread_local bool s_active;
};

/// Find the topmost referenced constant variable declaration when the given variable
/// declaration value is an identifier. Works only for constant variable declarations.
/// Returns nullptr if an identifier in the chain is not referencing a constant variable declaration.
VariableDeclaration const* rootConstVariableDeclaration(VariableDeclaration const& _varDecl);

/// Returns true if the constant variable declaration is recursive.
bool isConstantVariableRecursive(VariableDeclaration const& _varDecl);

/// Returns the innermost AST node that covers the given location or nullptr if not found.
ASTNode const* locateInnermostASTNode(int _offsetInFile, SourceUnit const& _sourceUnit);

/// @returns @a _expr itself, in case it is not a unary tuple expression. Otherwise it descends recursively
/// into unary tuples and returns the contained expression.
Expression const* resolveOuterUnaryTuples(Expression const* _expr);

/// @returns the type of an expression and asserts that it is present.
Type const* type(Expression const& _expression);
/// @returns the type of the given variable and throws if the type is not present
/// (this can happen for variables with non-explicit types before their types are resolved)
Type const* type(VariableDeclaration const& _variable);

/// @returns The number of slots occupied by all state variables in contract's inheritance hierarchy,
/// located in @a _location (either storage or transient storage).
bigint contractStorageSizeUpperBound(ContractDefinition const& _contract, VariableDeclaration::Location _location);

/// Slots occupied by @_type.
/// A mapping occupies one slot, unless @_storageLayoutV2 is set. Then it occupies
/// 2**160 slots for every slot of its leaf value. Nested mappings share that one
/// range: the leaf is the first value that is not itself a mapping. The result
/// may be >= 2**256.
bigint storageSlotCount(Type const& _type, bool _storageLayoutV2);

/// Slots occupied by the persistent state variables of @_contract, measured from slot zero.
/// Does not include a custom layout base. May be >= 2**256.
bigint contractStorageSize(ContractDefinition const& _contract, bool _storageLayoutV2);

/// @returns The base slot of the inheritance hierarchy rooted at the specified contract.
/// The value comes from the inheritance specifier of the contract and defaults to zero.
/// The value is zero also when the contract is an interface or a library (and cannot have storage).
/// Assumes analysis was successful.
u256 layoutBaseForInheritanceHierarchy(ContractDefinition const& _topLevelContract, DataLocation _location);

/// @returns The storage namespace base address using the ERC-7201 formula, if it can be calculated at compile time.
/// Assumes FunctionCall refers to erc7201 builtin.
std::optional<u256> erc7201CompileTimeValue(FunctionCall const& _erc7201Call);

/// A StorageLayoutV2 index chain whose every key is present and whose root is a
/// raw slot (a state variable, or a mapping member of a storage struct).
/// ``keys`` runs from the outer key to the inner key. The indexed type is not a mapping.
struct DirectStorageMappingIndex
{
	Expression const* root = nullptr;
	std::vector<Expression const*> keys;
};

/// The chain, when @_index can be compiled as a direct slot calculation.
/// Absent when the layout is inactive, a key is missing, the result is still a
/// mapping, or the root is a pointer that already carries keys.
std::optional<DirectStorageMappingIndex> directStorageMappingIndex(IndexAccess const& _index);

}
