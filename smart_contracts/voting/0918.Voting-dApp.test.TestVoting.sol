pragma solidity ^0.4.17;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";

contract TestVoting {
    Voting voting = Voting(DeployedAddresses.Voting());

    //test the voting function
    function testVoteForCandidates() public {
        //bytes32[3] = names;
        //names[0] = "Jose"; 
        uint candidate = voting.voteForCandidate("Jose");
        uint expected = 1;
        Assert.equal(candidate, expected, "You now have one vote");
    }
    //testing the number of candidates votes
    function testCandidatesVotes() public {
        uint candidate = voting.totalVotesFor("Jose");
        uint expected = 1;
        Assert.equal(candidate, expected, "No votes yet");
    }
    //validate the candidate
    // function testValidateCandidate() public {
    //     uint256 candidate = voting.validateCandidate("Nick");
    //     uint256 expected = true;
    //     Assert.equal(candidate, expected, "Candidate is found");
    // }
}