// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../PriceManager.sol";

contract TestPriceManager is PriceManager {
    constructor(address _factory)
        PriceManager(_factory)
    {
    }

    function setFactory(address _factory) external {
        factory = IExecutionPriceFactory(_factory);
    }
}