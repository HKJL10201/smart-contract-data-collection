// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import "./Candidate.sol";
import "./ElectionHelper.sol";


contract Vote is Candidate, ElectionHelper {
    modifier hasNotVoted(uint _electionId) {
        require (!this.hasAlreadyVoted(_electionId), "User has already voted");
        _;
    }

    function hasAlreadyVoted(uint _electionId) external view returns (bool) {
        return elections[_electionId].voters[msg.sender];
    }

    /**
     * Gives one note to each candidates of the election
     */
    function voteToElection(uint _electionId, uint[] calldata _notes) external hasNotVoted(_electionId) {
        require(elections[_electionId].candidatesCount == _notes.length, "Not same amount of candidates and votes");
        for (uint i = 0; i < elections[_electionId].candidatesCount; i++){
            addNote(_electionId, i, _notes[i]);
        }
        addVoter(_electionId);
    }

}