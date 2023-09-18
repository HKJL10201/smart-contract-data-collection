pragma solidity ^0.5.0;

contract ElectionBallot {

    // Model a Candidate / proposal
    struct Candidate{
        // uint id;
        bytes32 name;
        uint voteCount;
    }

    // store Candidate
    mapping (uint => Candidate ) public candidates;

     // store Candidates count
    uint public candidatesCount;

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
    }

    // stores a `Voter` struct for each possible address.
    mapping (address => Voter ) public voters;

    address public electionCommission;

    // Constractor to create a new Election  Ballot to choose one of `proposalNames`.
    constructor(bytes32[] memory proposalNames) public {
        electionCommission = msg.sender;

        // For each of the provided proposal names, create a new proposal object and add it to the List of Candidates.
        for (uint i = 0; i < proposalNames.length; i++) {
            addCandidate(proposalNames[i]);
        }
    }

    // add Candidate
    function addCandidate(bytes32  _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(_name, 0);
    }

    // Give `voter` the right to vote on this election ballot. only be called by `Election Commission`.
    function giveRightToVote(address[] memory _voters) public {
        // check the Election Commissiion
        require(msg.sender == electionCommission, "Only Election Commission can give right to vote.");

        for (uint i = 0; i < _voters.length; i++) {
            // check whether Voter alredy voted
            require(!voters[_voters[i]].voted, "The voter already voted.");

            // check voter wieght equal to zero
            require(voters[_voters[i]].weight == 0);

            // providing voter wieght to the voter.
            voters[_voters[i]].weight = 1;
        }
    }

    // casting vote
    function vote (uint _candidateId) public {

        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");

        // require that they haven't voted before
        require(!sender.voted, "Already voted.");

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        sender.voted = true;

        // update candidate vote count
        candidates[_candidateId].voteCount += sender.weight;

        // trigger voted event
        emit votedEvent(_candidateId, candidates[_candidateId].name, candidates[_candidateId].voteCount);
    }

    // voted event
    event votedEvent (
        uint indexed _candidateId,
        bytes32 indexed _candidateName,
        uint voteCount
    );

    // get Winner name and Vote count
    function  getWinner() public view returns ( bytes32 winnerName_, uint winningVoteCount )
    {
        for (uint p = 1; p <= candidatesCount; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winnerName_ = candidates[p].name;
            }
        }
    }
}
