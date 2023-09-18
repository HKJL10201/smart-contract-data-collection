pragma solidity ^0.4.20;

contract BallotSimplified {

    struct voter {
        uint weight;
        bool voted;
        uint8 vote;
    }

    mapping (address => voter) voters;
    
    struct proposal {
        uint voteCount;
    }

    proposal[] proposals;
    uint startTime;
    address chairperson;

    enum state {init, reg, vote, done}
    state public prestate = state.init;

    modifier validState(state reqState)
    { require(prestate == reqState);
      _;
    }

    event votingCompleted();

    function BallotSimplified(uint8 nProposals) public {
        startTime = now;
        chairperson = msg.sender;
        voters[chairperson].weight = 2;   // for testing purposes
        proposals.length = nProposals;
        prestate = state.reg;
    }

    function register(address voter_) public validState(state.reg) {
        // if (prestate != state.reg) {return;}
        if(msg.sender != chairperson || voters[voter_].voted) {return;}
        voters[voter_].weight = 1;
        voters[voter_].voted = false;
        if (now > (startTime + 20 seconds)) {prestate = state.vote; startTime = now;}
    }

    function vote (uint8 prop) public  validState(state.vote) {
        // if (prestate != state.vote) {return;}
        if (voters[msg.sender].voted || prop >= proposals.length) {return;}
        proposals[prop].voteCount += voters[msg.sender].weight;
        voters[msg.sender].vote = prop;
        voters[msg.sender].voted = true;
        if (now > (startTime + 20 seconds)) {prestate = state.done; votingCompleted;}
    }

    function winningProposal() public validState(state.done) constant returns (uint8 winner) {
        // if (prestate != state.done) {return;}
        uint256 winningVoteCount = 0;
        for (uint8 i=0; i<proposals.length; i++) 
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winner = i;
        assert(winningVoteCount > 0);
            }
    }
          
}