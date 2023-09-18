// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract usd is ERC20, Ownable {

    constructor() ERC20("usd", "USD") {}

    function mint(address _to, uint _amount) external {
        _mint(_to, _amount);
    }

    function withdraw(uint _amount) external {
        _burn(msg.sender, _amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}