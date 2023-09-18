// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    address public immutable owner;

    constructor()
        // solhint-disable-next-line no-empty-blocks
        ERC20("TST", "TestToken")
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function mint(address sender, uint256 amount) external onlyOwner {
        _mint(sender, amount);
    }
}
