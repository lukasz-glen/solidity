pragma experimental StorageLayoutV2;

contract C {
    struct Pair {
        uint x;
        uint y;
    }
    mapping(uint => mapping(uint => Pair)) m;
    uint tail;

    function set(uint k1, uint k2, uint x, uint y) public {
        m[k1][k2] = Pair(x, y);
    }
    function get(uint k1, uint k2) public returns (uint, uint) {
        return (m[k1][k2].x, m[k1][k2].y);
    }
    function tailSlot() public returns (uint s) {
        assembly { s := tail.slot }
    }
    function raw(uint k1, uint k2) public returns (uint x, uint y) {
        uint start;
        assembly { start := m.slot }
        uint loc = start + uint256(uint160(uint256(keccak256(abi.encode(k1, k2))))) * 2;
        assembly {
            x := sload(loc)
            y := sload(add(loc, 1))
        }
    }
}
// ----
// tailSlot() -> 0x20000000000000000000000000000000000000000
// set(uint256,uint256,uint256,uint256): 5, 6, 8, 9 ->
// get(uint256,uint256): 5, 6 -> 8, 9
// raw(uint256,uint256): 5, 6 -> 8, 9
