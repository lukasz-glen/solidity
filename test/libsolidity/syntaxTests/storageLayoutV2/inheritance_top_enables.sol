==== Source: base ====
contract Base {
    string s;
}
==== Source: top ====
pragma experimental StorageLayoutV2;
import "base";
contract Top is Base {
    uint x;
}
// ----
// TypeError 2735: (base:20-28): Type "string" is not allowed in storage for contract "Top" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
