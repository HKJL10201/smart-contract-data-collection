pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BancorFormula.sol";
// learn more: https://docs.openzeppelin.com/contracts/3.x/erc20


contract SheetFaucet is Ownable {
    IERC20 sheet;
    uint256 public withdrawAmount = 10000 ether;

    constructor(address _SHEET) {
        sheet = IERC20(_SHEET);
    }

    function withdraw() external {
        require(sheet.balanceOf(address(this)) > withdrawAmount, "No more SHEET to withdraw. Send some back if you have :)");
        sheet.transfer(msg.sender,withdrawAmount);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
