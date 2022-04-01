// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import '../interfaces/IPriceCalculator.sol';

contract TestPriceCalculator is IPriceCalculator {

    constructor() {}

    /* ========== VIEWS ========== */

    // Return constant price for testing.
    function getUSDPrice(address asset) external view override returns (uint) {
        require(asset != address(0), "TestPriceCalculator: invalid asset address");

        return 5e18;
    }
}