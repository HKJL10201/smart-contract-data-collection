pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    address chairperson;
    
    struct Voter {
        uint vote;
        bool voted;
        uint weight;
    }

    struct Proposal {
        uint voteCount;
    }

    mapping(address => Voter) voters;
    Proposal[] proposals;

    enum Phase {Init, Regs, Vote, Done};
    Phase private state = Phase.Init;

    /** Gate Keepers */
    modifier onlyChairperson {
        /**
        * Require function is used for validation of
        * 1. data
        * 2. computation
        * 3. parameter values
        * Similarly to an assert function, it reverts the computation once the supplied condition is not met
        */
        require(chairperson == msg.sender);
        _; /** Continue execution of actual logic guarded by this modifier */
    }

    modifier validPhase(Phase phase) {
        require(state == phase);
        _;
    }

    modifier validProposal(uint proposalIndex) {
        require(proposalIndex < proposals);
        _;
    }

    modifier hasNotVoted(address voter) {
        require(!voters[voter].voted);
        _;
    }

    modifier onlyVoter(address voter) {
        _;
    }

    constructor(uint _proposals) public {
        chairperson = msg.sender; // Contract deployer is the admin
        voters[chairperson].weight = 2; // Chairperson has the highest vote weight

        /** Initial Proposals */
        for(uint proposal = 0; proposal < _proposals; proposal++) {
            proposals.push(Proposal(0)); // Create proposal and save it in the proposals array
        }
    }

    function changePhase(Phase phase) public onlyChairperson {
        require(phase > state) /** State transition allowed : 0 -> 1 -> 2 -> 3 */

        state = phase;
    }

    function register(address voter) public validPhase(Phase.Regs) onlyChairperson  hasNotVoted(voter) {
        voters[voter].weight = 1;
        voters[voter].voted = false;
    }

    function vote(uint proposal) public validProposal(proposal) onlyVoter validPhase(Phase.Vote) hasNotVoted(msg.sender) returns (bool) {
        Voter memory voter = voters[msg.sender];
        voter.voted = true;
        voter.vote = proposal;
        proposals[proposal].voteCount += voter.weight;

        return true;
    }

    function requestWinner() public validPhase(Phase.Done) view returns (uint winningProposal, uint voteCount) {
        voteCount = 0;
        
        for(unit proposal = 0; proposal < proposals.length; proposal++) {
            if(proposals[proposal].voteCount > voteCount) {
                voteCount = proposals[proposal].voteCount;
                winningProposal = proposal;
            }
        }

        /** 
        * Atleast, a winning proposal must have 3 vote counts [rule implemented using assert function]
        * Actually, assert function is only used to manage exceptions 
        * [The usage here might not be appropriate, Only used here to establish the fact that it works similarly
        * to require but the context of application differs]
        * And it is important to note that it costs more in wasted blockchain gas than require
        */
        assert(voteCount >= 3);
    }
}