pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MOKToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MOK Token", "MOK") {
        _mint(msg.sender, initialSupply);
    }
}
