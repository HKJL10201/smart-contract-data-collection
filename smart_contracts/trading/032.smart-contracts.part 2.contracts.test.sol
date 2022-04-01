// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Test {
    address public platform;

    constructor(address _platform) {
        platform = _platform;
    }

    function testFunction(bytes memory callData) external returns (bool) {
        (bool success, ) = address(platform).call(callData);
        return success;
    }
}
