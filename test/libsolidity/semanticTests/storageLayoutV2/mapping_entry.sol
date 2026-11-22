pragma experimental StorageLayoutV2;

contract C {
    uint a;
    mapping(uint => uint) m;
    uint b;

    function set(uint k, uint v) public {
        m[k] = v;
    }
    function get(uint k) public returns (uint) {
        return m[k];
    }
    function slots() public returns (uint slotA, uint slotM, uint slotB) {
        assembly {
            slotA := a.slot
            slotM := m.slot
            slotB := b.slot
        }
    }
    function raw(uint k) public returns (uint) {
        uint start;
        assembly { start := m.slot }
        uint loc = start + uint160(uint256(keccak256(abi.encode(k))));
        uint value;
        assembly { value := sload(loc) }
        return value;
    }
}
// ----
// slots() -> 0, 1, 0x10000000000000000000000000000000000000001
// set(uint256,uint256): 42, 7 ->
// get(uint256): 42 -> 7
// raw(uint256): 42 -> 7
