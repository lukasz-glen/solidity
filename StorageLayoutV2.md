# StorageLayoutV2

The experiment 8.

To do less hashing in Ethereum.
With the experimental StorageLayoutV2 feature in Solidity.

## Problem

Hashing is common in blockchain.
It turned out to be a problem in Zero Knowledge Proofs.
ZK Layer 2 and ZKEVM need to generate proofs of executed transactions.
Hashing causes significant growth in hardware requirements,
a generation time and a proof size.

There are two groups of hashing usage.
The first is blockchain state updates, including events,
and block hash calculation.
The second is KECCAK256 opcode executions performed by
contracts and transactions.
The majority of hash usage falls into the first group actually.
It is 80-90%.

There are efforts to alleviate the incurred computation work.
Including:
use more ZK friendly hashing algorithm different than Keccak256,
enhancements in proving systems,
use more ZK friendly tries like Verkle,
changes in blockchain state structure,
etc.

This work focuses on contract level hashing.
It won't solve the main problem
but combined with other improvements may do the job.

## Idea

Most of the contracts are solidity sourced.
The idea is to modify the solidity compiler,
without modifying the language,
so the compiler output has reduced the number of hashing.

Contracts are using hashing mostly to
calculate accessed storage slots
and signature verification.
Signature verification is a part of contract logic.
But storage access is in the compiler's hand.
So this work is about modifying the storage layout.

A solidity contract defines state variables.
All state variables with assigned storage forms the storage layout.
And the compiler maps it into storage space.
In a short and general overview.
The standard compiler assigns fixed slots
for fixed sized variables.
Even ERC-7201 (storage namespaces) is using fixed slots actually.
In the case of area variables, dynamic sized variables,
an entry slot is calculated by a hash.
Especially for mapping types,
the key depends on input unknown in the compile time
and must be calculated on-chain.
The idea is that potentially large data chunks
of unspecified size are "randomly" placed in storage.
It is safe under the assumption of hash collision resistance.

To reduce hashing, a "random" slot allocations have to be limited.
The idea focuses on the mappings.
Ethereum assumes 160 security bits, as it is in the address type.
It is common to have mappings with address key,
for instance `mapping(address=>uint256) balance`.
The StorageLayoutV2 feature statically assigns `2^160*(value type slots)` slots
for the exclusive use for each mapping.
To get an entry slot, a key has to be cut to 160 bits,
but that's safe.
To access the entry simply look up a position in the reserved space.
Moreover, if a key is 160 bits or less in size,
no hash and cut is needed.

For example.
Consider the state variables
```text
mapping(address=>uint256) balance;
mapping(uint256=>address) owner;
mapping(address=>mapping(address=>uint256)) allowance;
```
and code snippet
```text
balance[user];
owner[tokenId];
allowance[spender][user]
```
then to calculate entry slots instead of this
```text
KECCAK256(user || balance_offset)
KECCAK256(tokenId || owner_offset)
KECCAK256(user || KECCAK256(spender || allowance_offset))
```
we use this
```text
balance_offset + user
owner_offset + KECCAK256(tokenId) mod 2^160
allowance_offset + KECCAK256(spender||user) mod 2^160
```
Note that if `tokenId` would be restricted to uint160
then one more hash would be skipped.

It is ok to use raw key values,
there will be no collision as each mapping uses a separate storage space.
As it was said, 160 bits are secure under general Ethereum assumptions.
2^160 slots for a single state variable seems to be a lot,
but you can still have up to 2^96 variables.


## Spec

Solidity source file may use directive
```text
pragma experimental StorageLayoutV2;
```
to use StorageLayoutV2 feature.
The feature is not inherited.
The settings in a source file of top contract determines
whether the contract is flagged or not
including the whole inheritance tree.
Internal libraries follow the same rule.

Any mapping type
reserves `2^160*(value type slots)` slots instead of 1.
In case of nested mappings,
`value type` refers to the final leaf value type.
It does not allocate "random" slots in storage to store data.
The key is calculated as
```text
k1 ; if the mapping is plain and key type fits into 160 bits
KECCAK256(k1) mod 2^160 ; if the mapping is plain and key type does not fit into 160 bits
k1..kn ; if the mapping is nested and packed key types fit into 160 bits
KECCAK256(k1||..||kn) mod 2^160 ; if the mapping is nested and packed key types do not fit into 160 bits.
```
The expression `k1..kn` is the packed keys in higher-to-lower-bits order.
The expression `k1||..||kn` is the concatenation of keys padded to 32-bytes words.
Note that the resulting key is always 160 bits.
The entry slot in storage is then calculated as
```text
offset + key * (value type slots)
```

Compilation fails if a type of state variable or
local storage pointer exceeds or is equal to 2^256 slots in size
according to the new sizes of mappings defined above.

Dynamic sized types, string, bytes, and dynamically sized arrays,
are not allowed as a state variable.
Including embeddings in structs, arrays, mapping keys and values.
They are still ok as local variables, constants, immutables,
transient variables.

The `.slot` attribute of local storage pointer of any
mapping type does not hold a slot number anymore.
It points to a memory block with data needed to compute
the entry slot when remaining keys are passed.
The first word in the memory block is the mapping tag:
0 - keys are concatenated and hashed, 1 - keys are packed without
hashing.
Note that the memory block
always references to a specific mapping in the contract's storage layout.
For instance it can be a state variable or a member of struct.
So the tag is determined.
The tag value is 1 if and only if the combined length of all keys
defined by the referenced mapping does not exceed 160 bits.
This is consistent with the above section on the entry slot computation.
For the tag 0 the memory block layout (in words) is
```text
0, offset, keys count, k1, k2, ...
```
where keys count is the number of passed keys,
not the number of defined keys in a mapping type.
For tag 1 the memory block layout (in words) is
```text
1, offset, bits filled, packed keys
```
where bits filled is the total of bits of passed keys,
not defined keys in a mapping type.
Note that the memory blocks apply only to local storage pointers
of mapping types, i.e.
when not all keys are passed.
`.slot` on a state variable is still the base offset.

## Considerations

The feature StorageLayoutV2 uses only fixed size types.
Mappings are considered fixed size now.
That's to guarantee that each state variable operates
on a separate storage space.
And that in turn allows to use raw key values when
a key fits in 160 bits.
As consequence, dynamic sized types like bytes and string
are not supported.
Declaration of state variable of dynamic sized type causes
compilation error.
As this is research work, such an approach is somehow acceptable.
But potential further development will have to solve this in a better way.
It would be the best if existing solidity contracts
would compile and work with StorageLayoutV2 feature.

Here are some examples how the entry slots are calculated.
Having these declarations
```text
mapping(address=>uint256) balance;
mapping(uint96=>mapping(uint8=>uint256)) collectedTokens;
mapping(address=>mapping(address=>uint256)) allowance;
```
and these lookups
```text
balance[owner]
collectedTokens[round][tokenType]
allowance[owner][spender]
```
the entry slots are
```text
balance_offset + owner
collectedTokens_offset + round * 256 + tokenType
allowance_offset + KECCAK256(owner || spender) mod 2^160
```
where both `owner` and `spender` are padded to 32-bytes words.

The `.slot` attribute of local storage pointer of any mapping type has
changed.
To calculate the entry slot without StorageLayoutV2
feature, a chain of hashes is computed.
For instance, having these declarations
```text
mapping(address=>uint256) balance;
mapping(uint96=>mapping(uint8=>uint256)) collectedTokens;
mapping(address=>mapping(address=>uint256)) allowance;
```
and these local storage pointers
```text
mapping(address=>uint256) storage p = balance;
mapping(uint8=>uint256) storage roundTokens = collectedTokens[round];
mapping(address=>uint256) storage ownerAllowance = allowance[owner];
```
the `.slot` attribute holds the values
```text
balance_offset
KECCAK256(round  || collectedTokens_offset)
KECCAK256(owner || allowance_offset)
```
With StorageLayoutV2 feature the `.slot` attribute
points to a memory block holding data in words
```text
1, balance_offset, 0, 0x0
1, collectedTokens_offset, 96, round
0, allowance_offset, 1, owner
```
The third pointer shows exactly what is the problem.
To calculate the entry slot a prefix hash cannot be
precomputed, all prefix data is needed.
This is a consequence of the new storage layout decisions.
And a flaw as well, because precomputed hashes cannot be reused.
Note that `.slot` semantics did not change for state variable
like `balance.slot`.
For the clarification, a pointer
```text
uint256 storage a = allowance[owner][spender];
```
without the StorageLayoutV2 feature it gives
```text
KECCAK256(spender || KECCAK256(owner || allowance_offset))
```
and with the feature on, it resolves to a slot number
not a memory block
```text
allowance_offset + KECCAK256(owner || spender) mod 2^160
```

Upgradable contracts use gaps, it is a declaration like
`uint256[50] private __gap;` at the end of contract.
It simply reserves space in advance for new state variables
in future contract versions.
It is clear that such a technique is much harder with the StorageLayoutV2 feature.

Proxy pattern rises a challenge to avoid storage conflicts.
There are two storage layouts, one is the proxy contract,
the other is the implementation contract - a delegatee.
They overlap in one deployed contract (under the proxy address)
and there is a risk that data is accidentaly overwritten
if the same slot is in use.
The solution is simple.
The proxy contract takes very little number of slots, usually
for the admin address and the implementation address.
And they have assigned hard to hit constant slot numbers, for instance
`KECCAK256("eip1967.proxy.admin")-1`.
In general it may be considered as "random" access
and this does not comply with StorageLayoutV2 feature.
It is left for further consideration.
But making sure that they are high enough
may do the work.
Note that slots defined by the EIP1967 standard
are already very high.

ERC-7201 should not be used with the StorageLayoutV2 feature.
It allocates space for state variables defined in base contracts
in "random" places.
So adding new variables in upgradable contracts is not a problem.
But such approach clearly is in contradiction with StorageLayoutV2 feature.

Declarations of extreme size variables like `mapping(address=>bytes32[2^96])`
break compilation. Another example is
```text
struct S {
    mapping(address=>uint256) balances
    ...
};
mapping(uint256=>S) history;
```
The size of struct `S` is 2^160,
so the size of `history` is 2^320.
On the other hand, the mapping embedded in the struct `S`
can be pulled out as a top level state variable
preserving logical structure of data
```text
struct S {
    ...
};
mapping(uint256=>S) history;
mapping(uint256=>mapping(address=>uint256)) historicalBalances;
```

The StorageLayoutV2 feature does not affect the transient storage.
Whether it should or not is left for further consideration.

The list of semantic changes:
- Storage Layout. In particular, if any assembly code calculates slots, it may not be portable.
- Dynamic sized types are not supported. State variables cannot be of type: string, bytes and dynamic sized arrays. Including embeddings in other types.
- The attribute `.slot` of local storage pointer of any mapping type changed as described above.
- Types that exceed 2^256 - 1 slots are not supported. It regards state variables and local storage pointers. See the above example with the struct `S`.

## Result

A [simple implementation of ERC20](https://github.com/lukasz-glen/StorageLayoutV2-contracts)
was used for a benchmark.
The table below shows the numbers of KECCAK256 opcode executions
in two compilations: with and without StorageLayoutV2 feature.

| ERC20 function | featured | non featured |
|----------|--------------|----------|
| approve | 1 | 2 |
| transfer | 0 | 3 |
| transferFrom | 2 | 7 |

The drop is significant.
Still one has to remember that triggered blockchain state updates
performs up to 40-50 hashes.

## Disclaimer

This work is a standalone research.
It is not related to the solidity team in any way,
or any of their affiliates.
The proposed feature is highly experimental,
not audited, and not production grade.
Authors do not take any responsibility
for caused damage, costs, or loss incurred.


