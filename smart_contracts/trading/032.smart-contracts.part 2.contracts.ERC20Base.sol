// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC20Base is ERC20, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address public admin;
    uint256 private _decimals = 6;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function updateAdmin(address newAdmin) external onlyRole(ADMIN_ROLE) {
        admin = newAdmin;
    }

    function mint(address to, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _mint(to, amount);
    }

    function burn(address owner, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _burn(owner, amount);
    }
}

// deployed to: 0x647B6Dd0D93cb6213EAa7b91EE6ABa46968D95A6 - rinkeby
// 0x916dCD5AEDE27Bf6C68b421C66d39E60CB2735B2 - binance
