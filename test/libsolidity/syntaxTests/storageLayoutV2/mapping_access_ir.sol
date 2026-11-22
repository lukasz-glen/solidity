pragma experimental StorageLayoutV2;

struct Pair { uint x; uint y; }

struct S {
    uint head;
    mapping(uint => uint) m;
    uint tail;
}

contract C {
    mapping(uint => uint) public m;
    mapping(uint => Pair) public pairs;
    S s;
    uint afterMappings;

    function set(uint k, uint v) public { m[k] = v; }
    function setPair(uint k, uint x, uint y) public {
        pairs[k].x = x;
        pairs[k].y = y;
    }
    function setS(uint k, uint v) public {
        s.m[k] = v;
        s.tail = v;
    }
    mapping(uint => mapping(uint => uint)) nested;
    mapping(uint => mapping(uint => mapping(uint => uint))) deep;
    function setNested(uint k1, uint k2, uint k3, uint v) public {
        nested[k1][k2] = v;
        deep[k1][k2][k3] = v;
        mapping(uint => uint) storage inner = nested[k1];
        inner[k2] = v;
    }
}
// ====
// compileViaYul: true
// ----
