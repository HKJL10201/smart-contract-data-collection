// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract MyToken is Context, ERC20 {

    constructor () ERC20("NToKenTest", "NTKT") {
        _mint(_msgSender(), 100000 * (10 ** 18));
    }

    function setApproval(address owner, address spender, uint256 amount) external {
        _approve(owner, spender, amount);
    }
}