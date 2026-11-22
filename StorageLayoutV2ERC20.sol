// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// comment this out to switch from the experimental to standard mode
pragma experimental StorageLayoutV2;

/// @title StorageLayoutV2ERC20
/// @author lukasz-glen
/// @notice This is a simple ERC20 implementation.
/// The experimental StorageLayoutV2 feature is used.
/// @dev The experimental StorageLayoutV2 feature impose limitations.
/// Dynamic sized types are not supported in storage.
/// So name and symbol are stored manually in a reseved space.
contract StorageLayoutV2ERC20 {
    // Metadata state variables
    bytes32[32] private __nameBytes;
    bytes32[32] private __symbolBytes;
    uint64 private __nameLength;
    uint64 private __symbolLength;
    uint8 public constant decimals = 18;

    // Supply and balances
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Standard ERC-20 Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function storeString(string memory s, uint256 target) internal {
        assembly {
            let len := mload(s)
            let pointer := add(s, 32)
            // 32 bytes is missing by purpose
            let endFullWords := add(s, len)
            let targetPointer := target
            // copy excpept the last word
            for { } lt(pointer, endFullWords) { } {
                sstore(targetPointer, mload(pointer))
                pointer := add(pointer, 32)
                targetPointer := add(targetPointer, 1)
            }
            // the last 32 bytes, if string is shorter than 32 bytes, then it is still ok
            let lastWord := mload(endFullWords)
            lastWord := shl(mul(sub(pointer, endFullWords), 8), lastWord)
            sstore(targetPointer, lastWord)
        }
    }

    function loadString(
        uint256 source,
        uint256 stringLength)
    internal view returns (string memory stringData) {
        assembly {
            // allocate space
            stringData := mload(0x40)
            // round up to the nearest 32-byte word boundary
            // add extra 32 bytes for legth word - 63 = 32 + 31
            mstore(0x40, add(stringData, and(add(stringLength, 63), not(31))))

            // set length
            mstore(stringData, stringLength)

            //copy data
            let sourcePointer := source
            let ptr := add(stringData, 32)
            let end := add(ptr, stringLength)
            for {} lt(ptr, end) {} {
                mstore(ptr, sload(sourcePointer))
                ptr := add(ptr, 32)
                sourcePointer := add(sourcePointer, 1)
            }
        }
    }

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        require(
            bytes(_name).length <= 32*32 && bytes(_symbol).length <= 32*32,
            "Name and Symbol cannot exceed 1024 bytes"
        );
        uint256 nameSlot;
        uint256 symbolSlot;
        assembly {
            nameSlot := __nameBytes.slot
            symbolSlot := __symbolBytes.slot
        }
        storeString(_name, nameSlot);
        storeString(_symbol, symbolSlot);
        (__nameLength, __symbolLength) = (uint64(bytes(_name).length), uint64(bytes(_symbol).length));
        
        uint256 supplyWithDecimals = _initialSupply * (10 ** uint256(decimals));
        totalSupply = supplyWithDecimals;
        balanceOf[msg.sender] = supplyWithDecimals;
        
        emit Transfer(address(0), msg.sender, supplyWithDecimals);
    }

    function symbol() public view returns (string memory) {
        uint256 symbolSlot;
        assembly {
            symbolSlot := __symbolBytes.slot
        }
        return loadString(symbolSlot, __symbolLength);
    }

    function name() public view returns (string memory) {
        uint256 nameSlot;
        assembly {
            nameSlot := __nameBytes.slot
        }
        return loadString(nameSlot, __nameLength);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Cannot approve zero address");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");

        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
}

