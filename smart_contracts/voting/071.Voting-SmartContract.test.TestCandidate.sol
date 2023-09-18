// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";
import "../contracts/Candidate.sol";

contract TestCandidate {
    Candidate voteContract;
    uint electionId;
    uint candidatesCount;
    string[] nameList;
    string[] nameList2;

    uint[] notes;
    uint[] notes2;
    uint[] notes3;

    // Run before every test function
    function beforeEach() public {
        delete nameList;
        delete notes;
        nameList.push("Jean");
        nameList.push("Michel");
        nameList.push("Bernard");

        voteContract = new Candidate();

        electionId = voteContract.createElection("Test election", nameList);
        candidatesCount = voteContract.getCandidatesCount(electionId);
    }

    function _voteForCandidates(uint[] memory _notes) internal {
        require(candidatesCount == _notes.length, "Not same amount of candidates and votes");
        for (uint candidateId = 0; candidateId < candidatesCount; candidateId ++) {
            voteContract.addNote(electionId, candidateId, _notes[candidateId]);
        }
        voteContract.incrementVoters(electionId);
    }

    function _generateSecondNameList() internal {
        delete nameList2;
        nameList2.push("Titi");
        nameList2.push("Gros");
        nameList2.push("Minet");
    }

    function test_GetCandidate() public {
        string memory expectedName = "Jean";
        uint expectedPercent = 0;
        uint expectedAverageNote = 0;
        (string memory name, uint percent, uint averageNote) = voteContract.getCandidate(electionId, 0);
        Assert.equal(string(name), string(expectedName), "Candidate name should be Jean");
        Assert.equal(uint(percent), uint(expectedPercent), "Candidate percent should be 0");
        Assert.equal(uint(averageNote), uint(expectedAverageNote), "Candidate average note should be 0");
    }

    function test_AddCandidate() public {
        voteContract.addCandidate(electionId, "Candidat Test");
        (string memory name, , ) = voteContract.getCandidate(electionId, 3);
        Assert.equal(string(name), string("Candidat Test"), "Candidate should be added to the list");
    }

    function test_GetCandidateNames_WithTwoElections() public {
        _generateSecondNameList();

        uint firstElectionId = voteContract.createElection("USA president election", nameList);
        uint secondElectionId = voteContract.createElection("Titi et gros minet", nameList2);
        (string memory name, , ) = voteContract.getCandidate(firstElectionId, 0);
        (string memory name2, , ) = voteContract.getCandidate(secondElectionId, 0);
        Assert.equal(string(name), string("Jean"), "Should return the right candidate name");
        Assert.equal(string(name2), string("Titi"), "Should return the right candidate name");
    }

    function test_AddNotes() public {
        notes.push(5);
        notes.push(4);
        notes.push(3);
        _voteForCandidates(notes);
        uint result = voteContract.getCandidateNote(electionId, 0, 5);
        Assert.equal(result, 1, "Note 5 should've been chosen once");
    }

    function test_CalculatePercent() public {
        notes.push(5);
        notes.push(4);
        notes.push(3);

        notes2.push(6);
        notes2.push(4);
        notes2.push(1);

        notes3.push(1);
        notes3.push(2);
        notes3.push(3);

        _voteForCandidates(notes);
        _voteForCandidates(notes2);
        _voteForCandidates(notes3);

        uint candidateId = 0;
        uint percent = voteContract.calculatePercentageOfNote(electionId, candidateId, 5);
        Assert.equal(percent, 33, "Percent of voters voting 5 for candidate Jean");
    }

    function test_ComputeAverageNote() public {
        notes.push(5);
        notes.push(4);
        notes.push(6);
        _voteForCandidates(notes);
        voteContract.computeAverageNote(electionId, 0);
        ( , , uint averageNote) = voteContract.getCandidate(electionId, 0);
        Assert.equal(averageNote, 5, "Candidate average note should be 5");
    }
}