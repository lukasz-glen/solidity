==== Source: base ====
contract Base {
    string s;
}
==== Source: mid ====
import "base";
contract Mid is Base {
    bytes b;
    uint y;
}
==== Source: top ====
pragma experimental StorageLayoutV2;
import "mid";
contract Top is Mid {
    uint z;
}
// ----
// TypeError 2735: (mid:42-49): Type "bytes" is not allowed in storage for contract "Top" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
// TypeError 2735: (base:20-28): Type "string" is not allowed in storage for contract "Top" under experimental StorageLayoutV2. Dynamically-sized types (string, bytes and arrays) are forbidden, including inside structs and as mapping keys or values.
