pragma experimental StorageLayoutV2;

contract C {
    struct S {
        uint head;
        mapping(uint => uint) m;
        uint tail;
    }
    S s;

    function set(uint k, uint v) public {
        s.head = 1;
        s.m[k] = v;
        s.tail = v + 1;
    }
    function get(uint k) public returns (uint head, uint stored, uint tailValue) {
        return (s.head, s.m[k], s.tail);
    }
    function raw(uint k) public returns (uint head, uint stored, uint tailValue) {
        uint base;
        assembly { base := s.slot }
        uint mapped = base + 1 + uint160(uint256(keccak256(abi.encode(k))));
        uint tailSlot = base + 1 + (uint(1) << 160);
        assembly {
            head := sload(base)
            stored := sload(mapped)
            tailValue := sload(tailSlot)
        }
    }
}
// ----
// set(uint256,uint256): 3, 4 ->
// get(uint256): 3 -> 1, 4, 5
// raw(uint256): 3 -> 1, 4, 5
