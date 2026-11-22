pragma experimental StorageLayoutV2;

contract C {
    uint a;
    mapping(uint => mapping(uint => uint)) public m;
    uint b;
    mapping(uint => mapping(uint => mapping(uint => uint))) public deep;
    mapping(address => mapping(address => uint)) public allowance;

    function slots() public returns (uint slotA, uint slotM, uint slotB) {
        assembly {
            slotA := a.slot
            slotM := m.slot
            slotB := b.slot
        }
    }
    function set(uint k1, uint k2, uint v) public {
        m[k1][k2] = v;
    }
    function setRef(uint k1, uint k2, uint v) public {
        mapping(uint => uint) storage inner = m[k1];
        inner[k2] = v;
    }
    function get(uint k1, uint k2) public returns (uint) {
        return m[k1][k2];
    }
    function raw(uint k1, uint k2) public returns (uint) {
        uint start;
        assembly { start := m.slot }
        uint loc = start + uint160(uint256(keccak256(abi.encode(k1, k2))));
        uint value;
        assembly { value := sload(loc) }
        return value;
    }
    function setDeep(uint k1, uint k2, uint k3, uint v) public {
        deep[k1][k2][k3] = v;
    }
    function rawDeep(uint k1, uint k2, uint k3) public returns (uint) {
        uint start;
        assembly { start := deep.slot }
        uint loc = start + uint160(uint256(keccak256(abi.encode(k1, k2, k3))));
        uint value;
        assembly { value := sload(loc) }
        return value;
    }
    function setAllowance(address owner, address spender, uint v) public {
        allowance[owner][spender] = v;
    }
    function rawAllowance(address owner, address spender) public returns (uint) {
        uint start;
        assembly { start := allowance.slot }
        uint loc = start + uint160(uint256(keccak256(abi.encode(owner, spender))));
        uint value;
        assembly { value := sload(loc) }
        return value;
    }
}
// ----
// slots() -> 0, 1, 0x10000000000000000000000000000000000000001
// set(uint256,uint256,uint256): 4, 5, 7 ->
// get(uint256,uint256): 4, 5 -> 7
// raw(uint256,uint256): 4, 5 -> 7
// m(uint256,uint256): 4, 5 -> 7
// setRef(uint256,uint256,uint256): 4, 6, 8 ->
// get(uint256,uint256): 4, 6 -> 8
// raw(uint256,uint256): 4, 6 -> 8
// setDeep(uint256,uint256,uint256,uint256): 1, 2, 3, 9 ->
// rawDeep(uint256,uint256,uint256): 1, 2, 3 -> 9
// deep(uint256,uint256,uint256): 1, 2, 3 -> 9
// setAllowance(address,address,uint256): 1, 2, 11 ->
// rawAllowance(address,address): 1, 2 -> 11
// allowance(address,address): 1, 2 -> 11
