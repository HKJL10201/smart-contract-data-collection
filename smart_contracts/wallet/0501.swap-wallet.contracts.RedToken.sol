pragma solidity >=0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RedToken is ERC20 {
    constructor() ERC20("Red Token", "Red") {
        _mint(msg.sender, 100000 * (10 ** decimals())); //mint tokens: supply amt of tokens with decimal
    }
}