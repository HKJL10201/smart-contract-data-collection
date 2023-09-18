// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20 {
    constructor() ERC20("Reward Token", "RVOTE") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
