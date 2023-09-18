// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC20/ERC20.sol";
import "../../token/ERC20/extensions/draft-ERC20Permit.sol";
import "../../access/Ownable.sol";

contract FiatWithPermit is ERC20Permit, Ownable {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) Ownable() ERC20(name, symbol) ERC20Permit(name) {
        _decimals = decimals_;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
