// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { ERC20Upgradeable } from "@openzeppelin/contracts/token/ERC20/ERC20Upgradeable.sol";

contract ERC20Mock is ERC20Upgradeable {
    bool public transferFromFail;
    bool public transferFail;

    function initialize(string memory name_, string memory symbol_) public initializer {
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (transferFromFail) {
            return false;
        }

        return ERC20Upgradeable.transferFrom(from, to, amount);
    }

    function setTransferFromFail(bool fail) external {
        transferFromFail = fail;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if (transferFail) {
            return false;
        }

        return ERC20Upgradeable.transfer(to, amount);
    }

    function setTransferFail(bool fail) external {
        transferFail = fail;
    }
}
