pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// learn more: https://docs.openzeppelin.com/contracts/3.x/erc20

contract SheetToken is ERC20 {
    // ToDo: add constructor and mint tokens for deployer,
    //       you can use the above import for ERC20.sol. Read the docs ^^^

     constructor() ERC20("TP Sheet", "SHEET") {
        //_mint() 1000000000 * 10 ** 18 to msg.sender
        _mint(msg.sender, 69420024 * 10 ** 18);
    }
}
