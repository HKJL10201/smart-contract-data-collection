//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "hardhat/console.sol";

library Reviews {
    struct Review {
        uint256 id;
        address author;
        uint256 rating;
        string review;
        uint256 unixtime;
        uint256 groupId;
        bool isVerified;
    }
}
