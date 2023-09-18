// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.8.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@4.8.2/access/AccessControl.sol";

contract HarryToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

        event HarryPurchased(address indexed receiver, address indexed buyer);


    constructor() ERC20("HarryToken", "HRT") {
        _mint(msg.sender, 1000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount * 10 ** decimals());
    }

        function buyOneHarry() public {
        _burn(_msgSender(), 1 * 10 ** decimals());
        emit HarryPurchased(_msgSender(), _msgSender());
    }

    function buyOneHarryFrom(address account) public {
        _spendAllowance(account, _msgSender(), 1 * 10 ** decimals());
        _burn(account, 1 * 10 ** decimals());
        emit HarryPurchased(_msgSender(), account);
    }
}
