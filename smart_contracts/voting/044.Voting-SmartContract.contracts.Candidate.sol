// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import "./ElectionFactory.sol";


contract Candidate is ElectionFactory {
    function addNote(uint _electionId, uint _candidateId, uint _noteId) public {
        elections[_electionId].candidates[_candidateId].notes[_noteId] ++;
    }

    function incrementVoters(uint _electionId) public {
        elections[_electionId].totalVoters ++;
    }

    function getCandidate(uint _electionId, uint _candidateId) external view returns (string memory, uint, uint) {
        Candidate storage candidate = elections[_electionId].candidates[_candidateId];
        return (candidate.name, candidate.percent, candidate.averageNote);
    }

    function getCandidatesCount(uint _electionId) external view returns (uint) {
        return elections[_electionId].candidatesCount;
    }

    function getCandidateNote(uint _electionId, uint _candidateId, uint _noteId) public view returns (uint) {
        return elections[_electionId].candidates[_candidateId].notes[_noteId];
    }

    function calculatePercentageOfNote(uint _electionId, uint _candidateId, uint _note) external view returns(uint){
        uint note = elections[_electionId].candidates[_candidateId].notes[_note];
        uint numberNote = note * 100;
        uint totalVoters = elections[_electionId].totalVoters;
        if (totalVoters == 0) {
            return 0;
        }
        return numberNote / totalVoters;
    }

    function computeAverageNote(uint _electionId, uint _candidateId) public {
        if (elections[_electionId].totalVoters == 0) {
            elections[_electionId].candidates[_candidateId].averageNote = 0;
        }
        else {
            for (uint i = 6; elections[_electionId].candidates[_candidateId].percent <= 50; i--){
                elections[_electionId].candidates[_candidateId].percent = elections[_electionId].candidates[_candidateId].percent + this.calculatePercentageOfNote(_electionId, _candidateId, i);
                if(elections[_electionId].candidates[_candidateId].percent >= 50){
                    elections[_electionId].candidates[_candidateId].averageNote = i;
                }
            }
        }
    }
}