pragma solidity >=0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BlueToken is ERC20 {
    constructor() ERC20("Blue Token", "Blu") {
        _mint(msg.sender, 100000 * (10 ** decimals())); //mint tokens: supply amt of tokens with decimal
    }
}