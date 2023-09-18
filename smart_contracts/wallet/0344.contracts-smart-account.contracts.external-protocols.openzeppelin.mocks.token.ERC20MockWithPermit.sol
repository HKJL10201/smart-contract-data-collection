// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC20/ERC20.sol";
import "../../token/ERC20/extensions/draft-ERC20Permit.sol";
import "../../access/Ownable.sol";

contract ERC20MockWithPermit is ERC20Permit, Ownable {
    constructor(string memory name, string memory symbol) Ownable() ERC20(name, symbol) ERC20Permit(name) {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}
