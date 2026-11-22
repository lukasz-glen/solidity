pragma experimental StorageLayoutV2;

struct Name {
    string value;
}

struct Outer {
    Name inner;
}

contract C {
    string s;
    bytes b;
    uint[] a;
    string[2] fixedStrings;
    uint[][2] fixedOfDynamic;
    bytes[] byteArrays;
    Name n;
    Outer o;
    mapping(string => uint) byName;
    mapping(bytes => uint) byBytes;
    mapping(uint => bytes) data;
    mapping(uint => uint[]) lists;
    mapping(uint => Name) names;
    mapping(uint => mapping(uint => string)) nested;
}
// ----
// TypeError 2735: (124-132): Type "string" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (138-145): Type "bytes" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (151-159): Type "uint256[]" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (165-187): Type "string[2]" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (193-217): Type "uint256[][2]" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (223-241): Type "bytes[]" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (247-253): Type "struct Name" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (259-266): Type "struct Outer" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (272-302): Type "mapping(string => uint256)" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (308-338): Type "mapping(bytes => uint256)" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (344-371): Type "mapping(uint256 => bytes)" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (377-406): Type "mapping(uint256 => uint256[])" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (412-439): Type "mapping(uint256 => struct Name)" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (445-492): Type "mapping(uint256 => mapping(uint256 => string))" is not allowed in storage for contract "C" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
