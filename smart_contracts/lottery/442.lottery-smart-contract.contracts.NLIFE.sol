// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NLIFE is ERC20 {
    constructor() ERC20("LotteryToken", "NLIFE") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}