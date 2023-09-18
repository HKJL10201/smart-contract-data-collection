//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "hardhat/console.sol";

library Users {
    struct User {
        uint256 upvotes;
        uint256 downvotes;
        bool isRegistered;
    }
}
