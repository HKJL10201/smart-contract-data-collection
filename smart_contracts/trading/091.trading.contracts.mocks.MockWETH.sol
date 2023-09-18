// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contractsV4/token/ERC20/ERC20.sol";
import "../interfaces/IWETH.sol";

contract MockWETH is ERC20, IWETH {
    constructor() ERC20("Wrapped Ether", "WETH") {}

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {
        deposit();
    }
}
