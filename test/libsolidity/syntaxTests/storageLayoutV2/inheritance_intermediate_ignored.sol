==== Source: base ====
contract Base {
    uint x;
}
==== Source: mid ====
pragma experimental StorageLayoutV2;
import "base";
contract Mid is Base {
    uint y;
}
==== Source: top ====
import "mid";
contract Top is Mid {
    string s;
    bytes b;
    uint[] a;
}
// ----
