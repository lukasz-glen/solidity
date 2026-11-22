==== Source: base ====
pragma experimental StorageLayoutV2;
contract Base {
    uint x;
}
==== Source: top ====
import "base";
contract Top is Base {
    string s;
}
// ----
