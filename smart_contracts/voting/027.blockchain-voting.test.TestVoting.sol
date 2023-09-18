pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";

contract TestVoting {
    Voting voting;

    string _description;
    bytes32[] _proposals;
    bytes32[] _tokens;

    function beforeAll() public {
        voting = Voting(DeployedAddresses.Voting());
        _description = "Should we trust blockchain for voting?";
        _proposals.push("yes");
        _proposals.push("no");
        _proposals.push("I don't know");
        _tokens.push("DFG87DF687W3Y");
        _tokens.push("893475I3M45YM");
        _tokens.push("HYAS76D76ASDA");
    }

    function testItHasACleanStorage() public {
        Assert.equal(voting.getPollsMapSize(), 0, "It should have a clean storage");
    }

    function testItCreatesAPoll() public {
        voting.createPoll(_description, _proposals, _tokens);
        Assert.equal(voting.getPollsMapSize(), 1, "It should create one poll");
    }

    function testItGetsAPoll() public {
        string memory description;
        uint proposals;
        bool closed;
        (description, proposals, closed) = voting.getPoll(0);
        Assert.equal(description, _description, "It should have the correct description");
        Assert.equal(proposals, _proposals.length, "It should have the correct number of proposals");
        Assert.isFalse(closed, "It should not be closed yet");
    }

    function testItGetsTheProposals() public {
        Assert.equal(voting.getProposal(0, 0), _proposals[0], "It should have the correct description");
        Assert.equal(voting.getProposal(0, 1), _proposals[1], "It should have the correct description");
        Assert.equal(voting.getProposal(0, 2), _proposals[2], "It should have the correct description");
    }

    function testItCastsTheVotes() public {
        voting.castVote(_tokens[0], 0, 1);
        voting.castVote(_tokens[1], 0, 2);
        voting.castVote(_tokens[2], 0, 1);
    }

    function testItClosesAPoll() public {
        bool closed;
        voting.closePoll(0);
        (,, closed) = voting.getPoll(0);
        Assert.isTrue(closed, "It should be closed");
    }

    function testItCountsTheVotes() public {
        Assert.equal(voting.getVoteCount(0, 0), 0, "The 1st proposal should not have votes");
        Assert.equal(voting.getVoteCount(0, 1), 2, "The 2nd proposal should have 2 votes");
        Assert.equal(voting.getVoteCount(0, 2), 1, "The 3rd proposal should have 1 vote");
    }
}
