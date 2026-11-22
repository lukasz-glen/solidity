pragma experimental StorageLayoutV2;

contract Ok {
    uint x;
    mapping(uint => uint) m;
}

contract Bad {
    string s;
}

contract AlsoBad {
    uint[] a;
}
// ----
// TypeError 2735: (115-123): Type "string" is not allowed in storage for contract "Bad" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (151-159): Type "uint256[]" is not allowed in storage for contract "AlsoBad" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
