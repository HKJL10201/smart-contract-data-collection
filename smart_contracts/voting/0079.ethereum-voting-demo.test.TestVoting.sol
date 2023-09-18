pragma solidity ^0.4.21;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";


/**
 * @title TestVoting
 * @dev The TestVoting contract is a test contract, and provides basic test cases
 * functions, this adds test cases for Voting contract.
 */
contract TestVoting {

    // Truffle will send the TestContract one Ether after deploying the contract.
    // this ether would be deducted from default account so make sure you have this in your defualt account
    uint public initialBalance = 1 ether;

    function testAllCandidates() public {
        Voting vote = Voting(DeployedAddresses.Voting());
        uint expected = 3;
        bytes32[3] memory voters = vote.getFixedSizeAllCandidatesArray();
        uint actual = voters.length;
        Assert.equal(actual, expected, "Initailly there should be 3 candidates");
    }
    
    function testInitialVoteCount() public {
        Voting vote = Voting(DeployedAddresses.Voting());
        uint expected = 0;
        bytes32[3] memory candidates = vote.getFixedSizeAllCandidatesArray();
        uint votesForRama = vote.totalVotesFor(candidates[0]);
        uint votesForNick = vote.totalVotesFor(candidates[1]);
        uint votesForJose = vote.totalVotesFor(candidates[2]);
        Assert.equal(votesForRama, expected, "Initailly there should be 0 votes for Rama");
        Assert.equal(votesForNick, expected, "Initailly there should be 0 votes for Nick");
        Assert.equal(votesForJose, expected, "Initailly there should be 0 votes for Jose");
    }

    function testTokenSold() public {
        Voting vote = Voting(DeployedAddresses.Voting());
        uint expected = 0;
        uint actual = vote.tokensSold();
        Assert.equal(actual, expected, "Initailly there should be 0 token sold");
    }

    function testGetTotalTokens() public {
        Voting vote = Voting(DeployedAddresses.Voting());
        uint expected = 1000;
        uint actual = vote.getTotalTokens();
        Assert.equal(actual, expected, "Initailly there should be 1000 total tokens to be sold");
    }
    
    function testBuyVotes() public {
        Voting vote = Voting(DeployedAddresses.Voting());
        uint expected = 10;
        uint fee = 1 ether;
        uint actual = vote.buy.value(fee)();
        Assert.equal(actual, expected, "1 ether should buy 10 votes");
    }

    function testVoteForCandidate() public {
        Voting vote = Voting(DeployedAddresses.Voting());
        uint expected = 5;
        vote.voteForCandidate("Rama", uint8(5));
        bytes32[3] memory candidates = vote.getFixedSizeAllCandidatesArray();
        uint votesForRama = vote.totalVotesFor(candidates[0]);
        Assert.equal(votesForRama, expected, "After voting there should be 5 votes for Rama");
    }
}