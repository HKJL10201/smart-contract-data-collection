//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VotingPlatformLib.sol";
import "./Vote.sol";

contract VotingPlatform {
    address public owner;
    Vote[] public votes;

    event VoteAdded(uint index);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Caller is not the owner');
        _;
    }

    function getVotesCount() external view returns (uint) {
        return votes.length;
    }

    function createVote(
        bool _multipleChoice,
        uint _dateOfStart,
        uint _dateOfEnd,
        uint _dateOfEndAddPrivateKeys,
        VotingPlatformLib.Candidate[] memory _candidates,
        uint _votersCount,
        uint _modulus,
        uint _exponent
    ) external onlyOwner {
        votes.push(
            new Vote(
                _multipleChoice,
                _dateOfStart,
                _dateOfEnd,
                _dateOfEndAddPrivateKeys,
                _candidates,
                _votersCount,
                _modulus,
                _exponent
            )
        );
        emit VoteAdded(votes.length - 1);
    }
}
