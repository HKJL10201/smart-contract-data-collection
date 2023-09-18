// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './BEP20.sol';

contract WalletikaToken is BEP20('Walletika', 'WTK') {
    uint256 private _initalSupply = 70000000e18;
    uint256 private _maxSupply = 100000000e18;

    constructor() public {
        _mint(owner(), _initalSupply);
    }

    function transferMultiple(address[] calldata addresses, uint256[] calldata amounts) external returns (bool) {
        require(addresses.length <= 100, "BEP20: addresses exceeds 100 address");
        require(addresses.length == amounts.length, "BEP20: mismatch between addresses and amounts count");

        uint256 totalAmount = 0;
        for (uint i=0; i < addresses.length; i++) {
            totalAmount = totalAmount + amounts[i];
        }

        require(balanceOf(_msgSender()) >= totalAmount, "BEP20: balance is not enough");

        for (uint i=0; i < addresses.length; i++) {
            transfer(addresses[i], amounts[i]);
        }

        return true;
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address spender, uint256 amount) external returns (bool) {
        _burnFrom(spender, amount);
        return true;
    }

    /* ========== OWNER FUNCTIONS ========== */

    function mint(uint256 amount) external onlyOwner returns (bool) {
        require(amount.add(totalSupply()) <= _maxSupply, "BEP20: amount exceeds max supply");

        _mint(owner(), amount);
        return true;
    }

    function recoverToken(address tokenAddress, uint256 amount) external onlyOwner returns (bool) {
        return IBEP20(tokenAddress).transfer(owner(), amount);
    }
}