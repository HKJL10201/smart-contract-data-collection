pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./ITagsRepository.sol";

contract MockTagsRepository is ITagsRepository {

    bool hasAllQueriedTags;

    constructor(bool willHaveAllQueriedTags) {
        hasAllQueriedTags = willHaveAllQueriedTags;
    }

    function vote(uint8, bytes32, uint256) override external {}

    function isRecentMMRRoot(uint8, bytes32) override external view returns (bool) {
        return hasAllQueriedTags;
    }

    function getRoundHeightForLastTag(uint8) override public pure returns (uint256) {
        return 42;
    }
}