==== Source: base ====
pragma experimental StorageLayoutV2;
contract Base {
    string s;
}
==== Source: top ====
import "base";
contract Top is Base {
    bytes b;
    uint x;
}
// ----
// TypeError 2735: (base:57-65): Type "string" is not allowed in storage for contract "Base" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
