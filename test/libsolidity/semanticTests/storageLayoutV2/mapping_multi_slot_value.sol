pragma experimental StorageLayoutV2;

contract C {
    struct Pair {
        uint x;
        uint y;
    }
    mapping(uint => Pair) m;
    uint tail;

    function set(uint k, uint x, uint y) public {
        m[k] = Pair(x, y);
    }
    function get(uint k) public returns (uint, uint) {
        return (m[k].x, m[k].y);
    }
    function tailSlot() public returns (uint s) {
        assembly { s := tail.slot }
    }
    function raw(uint k) public returns (uint x, uint y) {
        uint start;
        assembly { start := m.slot }
        uint loc = start + uint256(uint160(uint256(keccak256(abi.encode(k))))) * 2;
        assembly {
            x := sload(loc)
            y := sload(add(loc, 1))
        }
    }
}
// ----
// tailSlot() -> 0x20000000000000000000000000000000000000000
// set(uint256,uint256,uint256): 5, 8, 9 ->
// get(uint256): 5 -> 8, 9
// raw(uint256): 5 -> 8, 9
