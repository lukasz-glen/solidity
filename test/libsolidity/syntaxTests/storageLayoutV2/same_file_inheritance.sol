pragma experimental StorageLayoutV2;

contract Base {
    string s;
    uint x;
}

contract Child is Base {
    bytes b;
}
// ----
// TypeError 2735: (58-66): Type "string" is not allowed in storage for contract "Base" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (112-119): Type "bytes" is not allowed in storage for contract "Child" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (58-66): Type "string" is not allowed in storage for contract "Child" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
