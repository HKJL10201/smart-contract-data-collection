// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract VotingSystem {
    enum Choice {
        YES,
        NO
    }

    string private _proposal = "Is DOOM a cool game ?";
    mapping(address => bool) private _voters;
    Choice[] private _votes;

    function getProposal() public view returns (string memory) {
        return _proposal;
    }

    function getVotes() public view returns (Choice[] memory) {
        return _votes;
    }

    function vote(Choice _choice) external {
        require(!_voters[msg.sender], "You have already voted.");

        _voters[msg.sender] = true;
        _votes.push(_choice);
    }
}
