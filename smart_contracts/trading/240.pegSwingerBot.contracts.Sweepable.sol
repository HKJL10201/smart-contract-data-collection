//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Sweepable is Ownable {
    constructor() {}

    function sweep(address _erc) public onlyOwner {
        IERC20 token = IERC20(_erc);
        uint256 balance = token.balanceOf(address(this));
        token.transferFrom(address(this), msg.sender, balance);
    }
}