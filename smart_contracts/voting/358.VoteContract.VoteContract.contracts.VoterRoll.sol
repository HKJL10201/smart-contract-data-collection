//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoterRoll is Ownable {
    // A voter roll to keep track of registered voters. Bool is true if voter
    // is registered 
    mapping (address => bool) voterRoll;
    // Vote status to check if the enrolled voter has voted. Bool is false if
    // voter has voted. Seems to duplicate voterRoll, but this separate mapping
    // is implemented so we can distinguish between voters who are enrolled but
    // has not voted, and voters who completely cannot vote at all
    mapping (address => bool) voterVoteStatus;

    modifier voterIsEnrolled() {
        require(voterRoll[msg.sender] == true, "Voter is not enrolled");
        _;
    }

    modifier hasNotVoted() {
        require(voterVoteStatus[msg.sender] == true, "Voter has already voted");
        _;
    }

    function enrollVoters(address[] memory _voterAddresses) external onlyOwner {
        for (uint256 i = 0; i < _voterAddresses.length; i++) {
            // Init the values in the mappings to be true. We use true instead
            // of false since all values in mappings are initialized to be false
            // or 0
            voterRoll[_voterAddresses[i]] = true;
            voterVoteStatus[_voterAddresses[i]] = true;
        }
    }

    function _mark_voter_voted(address _voter) internal {
        voterVoteStatus[_voter] = false;
    }

    function checkVotingStatus(address _voterAddress) external view returns (bool) {
        return voterVoteStatus[_voterAddress];
    }

    function checkVoterEnrollment(address _voterAddress) external view returns (bool) {
        return voterRoll[_voterAddress];
    }
}