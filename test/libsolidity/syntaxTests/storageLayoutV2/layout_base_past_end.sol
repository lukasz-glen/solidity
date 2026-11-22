pragma experimental StorageLayoutV2;
contract C layout at 2**256 - 2**160 {
    mapping(uint => uint) m;
}
// ----
// TypeError 5015: (58-73): Contract extends past the end of storage when this base slot value is specified.
