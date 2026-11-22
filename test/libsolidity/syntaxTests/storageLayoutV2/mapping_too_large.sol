pragma experimental StorageLayoutV2;

struct Inner {
    mapping(uint => uint) m;
}

contract Base {
    mapping(uint => mapping(uint => uint)) nested;
}

contract Child is Base {
    mapping(uint => Inner) throughStruct;
}
// ----
// TypeError 7455: (184-220): Type "mapping(uint256 => struct Inner)" does not fit into storage for contract "Child" under experimental StorageLayoutV2. A mapping reserves 2**160 slots for each slot of its value type. Nested mappings share one such range. The layout must fit into 2**256 slots.
