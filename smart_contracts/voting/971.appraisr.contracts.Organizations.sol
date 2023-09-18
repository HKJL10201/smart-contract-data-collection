//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "hardhat/console.sol";

library Organizations {
    struct Organization {
        uint256 orgId;
        string name;
        address addr;
        bool isActive;
        bool isCreated;
    }
}
