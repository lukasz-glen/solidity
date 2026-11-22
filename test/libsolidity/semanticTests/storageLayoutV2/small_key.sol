pragma experimental StorageLayoutV2;

contract C {
    mapping(address => uint) public addrs;
    mapping(uint8 => uint) public small;
    mapping(uint8 => mapping(uint8 => uint)) nested;
    mapping(address => mapping(uint8 => uint)) mixed;
    mapping(bytes20 => uint) public rawBytes;
    uint tail;

    function tailSlot() public returns (uint s) {
        assembly { s := tail.slot }
    }
    function setAddr(address k, uint v) public { addrs[k] = v; }
    function rawAddr(address k) public returns (uint) {
        uint start;
        assembly { start := addrs.slot }
        uint loc = start + uint160(k);
        uint value;
        assembly { value := sload(loc) }
        return value;
    }
    function setSmall(uint8 k, uint v) public { small[k] = v; }
    function rawSmall(uint8 k) public returns (uint) {
        uint start;
        assembly { start := small.slot }
        uint loc = start + uint(k);
        uint value;
        assembly { value := sload(loc) }
        return value;
    }
    function setNested(uint8 k1, uint8 k2, uint v) public { nested[k1][k2] = v; }
    function setNestedRef(uint8 k1, uint8 k2, uint v) public {
        mapping(uint8 => uint) storage inner = nested[k1];
        inner[k2] = v;
    }
    function rawNested(uint8 k1, uint8 k2) public returns (uint) {
        uint start;
        assembly { start := nested.slot }
        uint loc = start + uint(k1) * 256 + uint(k2);
        uint value;
        assembly { value := sload(loc) }
        return value;
    }
    function setMixed(address k1, uint8 k2, uint v) public { mixed[k1][k2] = v; }
    function rawMixed(address k1, uint8 k2) public returns (uint) {
        uint start;
        assembly { start := mixed.slot }
        uint loc = start + uint160(uint256(keccak256(abi.encode(k1, k2))));
        uint value;
        assembly { value := sload(loc) }
        return value;
    }
    function setBytes(bytes20 k, uint v) public { rawBytes[k] = v; }
    function rawBytesAt(bytes20 k) public returns (uint) {
        uint start;
        assembly { start := rawBytes.slot }
        uint loc = start + uint160(k);
        uint value;
        assembly { value := sload(loc) }
        return value;
    }
}
// ----
// tailSlot() -> 0x50000000000000000000000000000000000000000
// setAddr(address,uint256): 0x1234, 5 ->
// rawAddr(address): 0x1234 -> 5
// addrs(address): 0x1234 -> 5
// setSmall(uint8,uint256): 7, 9 ->
// rawSmall(uint8): 7 -> 9
// small(uint8): 7 -> 9
// setNested(uint8,uint8,uint256): 1, 2, 4 ->
// rawNested(uint8,uint8): 1, 2 -> 4
// setNestedRef(uint8,uint8,uint256): 1, 3, 6 ->
// rawNested(uint8,uint8): 1, 3 -> 6
// setMixed(address,uint8,uint256): 0x11, 4, 8 ->
// rawMixed(address,uint8): 0x11, 4 -> 8
// setBytes(bytes20,uint256): left(0x00112233445566778899aabbccddeeff00112233), 12 ->
// rawBytesAt(bytes20): left(0x00112233445566778899aabbccddeeff00112233) -> 12
// rawBytes(bytes20): left(0x00112233445566778899aabbccddeeff00112233) -> 12
