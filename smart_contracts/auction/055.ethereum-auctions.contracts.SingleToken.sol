// This implements the ERC179 token standard a single indivisible token.

pragma solidity ^0.4.18;

import "./interfaces/EIP179/ERC179Interface.sol";

contract SingleToken is ERC179Interface {
    address public owner;
    
    string public name;
    string public symbol;

    function SingleToken(
        string _tokenName,
        string _tokenSymbol
    ) public 
    {
        owner = msg.sender;               // Give the creator the initial tokens
        name = _tokenName;                // Set the name for display purposes
        symbol = _tokenSymbol;            // Set the symbol for display purposes
    }

    function decimals() public view returns (uint8) {
        return 0;
    }
    
    function totalSupply() public view returns (uint256) {
        return 1;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        if (_owner == owner) {
            return 1;
        } else {
            return 0;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf(msg.sender));

        if (_value == 1) {
            owner = _to;
        }

        Transfer(msg.sender, _to, _value);

        return true;
    }
}