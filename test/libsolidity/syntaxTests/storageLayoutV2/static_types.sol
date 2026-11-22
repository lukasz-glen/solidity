pragma experimental StorageLayoutV2;

type MyUint is uint;

enum E { A, B }

struct Point {
    uint x;
    uint y;
}

struct WithMap {
    mapping(uint => uint) m;
    uint z;
}

contract Other {}

library L {
    string constant NAME = "L";
}

string constant FILE_NAME = "file";

contract C {
    uint x;
    uint[3] xs;
    bytes32 y;
    bytes1 z;
    address a;
    bool b;
    E e;
    MyUint u;
    Other other;
    Point p;
    Point[2] ps;
    WithMap w;
    mapping(uint => uint) m;
    mapping(address => bytes32) n;
    mapping(uint => uint)[2] fixedMappings;
    mapping(uint => Point) points;
    mapping(uint => mapping(uint => uint)) nested;
    mapping(address => mapping(address => uint)) allowance;
    mapping(uint => mapping(uint => mapping(uint => uint))) deep;
    string constant LABEL = "label";
    bytes constant DATA = hex"01";
    uint immutable im = 1;

    function f(string memory s, bytes calldata data, uint[] memory arr) public pure returns (uint) {
        return bytes(s).length + data.length + arr.length;
    }
}
// ----
