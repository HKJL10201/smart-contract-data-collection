// sourced: https://theethereum.wiki/w/index.php?title=ERC20_Token_Standard&action=edit
pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------------------------
// Sample fixed supply token contract
// Enjoy. (c) BokkyPooBah 2017. The MIT Licence.
// ----------------------------------------------------------------------------------------------
// Note: heavily modified from original

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20InterfaceOnlyBalance {
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract FakeErc20 is ERC20InterfaceOnlyBalance {
    string public constant symbol = "DEVERC20";
    string public constant name = "Example Fixed Supply Token";
    uint8 public constant decimals = 18;

    mapping (address => uint256) balances;

    // Owner of this contract
    address public owner;

    // Constructor
    constructor() public {
        owner = msg.sender;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return 1337000000000000000000 + balances[_owner];  // null addition avoids some linter errors
    }
}
