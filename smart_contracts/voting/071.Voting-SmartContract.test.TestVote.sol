// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";
import "../contracts/Vote.sol";

contract TestVote {
    Vote voteContract;
    uint electionId;
    string[] namesList;

    // Run before every test function
   function beforeEach() public {
        delete namesList;
        namesList.push("Candidate 1");
        namesList.push("Candidate 2");
        namesList.push("Candidate 3");

        voteContract = new Vote();
        electionId = voteContract.createElection("TestElection", namesList);
   }

    function _addSixCandidates() internal {
        voteContract.addCandidate(electionId, "Jean");
        voteContract.addCandidate(electionId, "Michelle");
        voteContract.addCandidate(electionId, "Norah");
        voteContract.addCandidate(electionId, "Alexandre");
        voteContract.addCandidate(electionId, "Marc");
        voteContract.addCandidate(electionId, "Pierre");
    }

    function _generateVotesForElection() internal view returns (uint[] memory) {
        uint[] memory generatedNotes = new uint[](voteContract.getCandidatesCount(electionId));
        for (uint i = 0; i < voteContract.getCandidatesCount(electionId); i++) {
            uint256 generatedNote = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 7;
            generatedNotes[i] = generatedNote;
        }
        return generatedNotes;
    }

     function _checkIfNotesAreAdded(uint[] memory notesSupposedlyAdded) internal view returns (bool) {
         for (uint i; i < voteContract.getCandidatesCount(electionId); i++) {
             if (voteContract.getCandidateNote(electionId, i, notesSupposedlyAdded[i]) != 1) {
                 return false;
             }
         }
         return true;
     }

    function test_WhenUserHasVoted_HasAlreadyVotedReturnsTrue() public {
        _addSixCandidates();
        uint[] memory generatedNotes = _generateVotesForElection();
        voteContract.voteToElection(electionId, generatedNotes);
        Assert.equal(voteContract.hasAlreadyVoted(electionId), true, "This user already voted");
    }

    function test_WhenUserHasNotVoted_HasAlreadyVotedReturnsFalse() public {
        Assert.equal(voteContract.hasAlreadyVoted(electionId), false, "This user has not voted");
    }

    function test_WhenUserHasVoted_NotesAreAddedToCandidates() public {
        _addSixCandidates();
        uint[] memory generatedNotes = _generateVotesForElection();

        voteContract.voteToElection(electionId, generatedNotes);

        bool notesAreAdded = _checkIfNotesAreAdded(generatedNotes);
        Assert.equal(bool(notesAreAdded), bool(true), "Notes should be added to candidates");
    }
}
