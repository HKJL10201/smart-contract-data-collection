// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Token is ERC1155 {
    uint256 public constant CURRENCY1 = 0;
    uint256 public constant CURRENCY2 = 1;

    constructor() ERC1155("") { }

    function mint(uint256 amount) public {
        require(amount > 0);
        _mint(msg.sender, CURRENCY1, amount, "");
        _mint(msg.sender, CURRENCY2, amount, "");
    }
}