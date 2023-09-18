// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contractsV4/token/ERC20/ERC20.sol";

contract MockERC20WithName is ERC20 {
    uint8 immutable decimals_;

    constructor(string memory name, string memory symbol, uint8 _decimals, uint256 amount) ERC20(name, symbol) {
        decimals_ = _decimals;
        _mint(msg.sender, amount);
    }

    function decimals() public view override returns (uint8) {
        return decimals_;
    }

    function mint(address account, uint256 amount) external returns (bool success) {
        _mint(account, amount);
        return true;
    }
}
