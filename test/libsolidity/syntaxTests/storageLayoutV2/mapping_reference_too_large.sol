pragma experimental StorageLayoutV2;

struct Huge {
    mapping(uint => mapping(uint => uint)) m;
}

contract C {
    function f(mapping(uint => mapping(uint => uint)) storage nested) internal {
        nested[1][2] = 3;
    }
    function g(Huge storage h) internal {
        h.m[1][2] = 3;
    }
    function viaRef(mapping(uint => mapping(uint => uint)) storage nested, uint k1) internal {
        mapping(uint => uint) storage inner = nested[k1];
        inner[2] = 3;
    }
}
// ----
