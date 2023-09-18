// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Election.sol";
import "./tokens/RewardToken.sol";
import "./tokens/VoteNFT.sol";

contract MainContract {
    uint256 public electionId = 0;
    mapping(uint256 => address) public Elections;

    // Main reward token instance
    RewardToken public immutable token;

    // Voter nft instance
    VoteNFT public immutable nft;

    // Reward token creation and nft contract creation
    constructor() {
        token = new RewardToken();
        nft = new VoteNFT();
    }

    function createElection(
        string[] memory _nda,
        string[] memory _candidates,
        uint256 electionLength
    ) public {
        Election election = new Election(
            address(token),
            address(nft),
            _nda,
            _candidates,
            electionLength
        );

        Elections[electionId] = address(election);
        electionId++;
    }
}
