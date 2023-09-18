pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract SampleToken is ERC20 {
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000000 * (10 ** uint256(decimals));
    string name;

    constructor(string _name) public {
        name = _name;
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}