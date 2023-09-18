pragma solidity >=0.4.17 <0.7.0;

contract BallotCreator {
    address[] public deployedBallots;
    address public electionCommision;
    
    modifier restricted() {
        require(msg.sender == electionCommision);
        _;
    }
    
    function BallotCreator() public {
        electionCommision = msg.sender;
    }
    
    function createBallot(string votingType, string area, address[] candidates) public restricted {
        address newBallot = new Ballot(votingType, area, candidates, msg.sender);
        deployedBallots.push(newBallot);
    }
    
    function getDeployedBallots() public view returns(address[]){
        return deployedBallots;
    }
}

contract Ballot {
    struct Candidate{
        string name;
        address candidateAddress;
        uint voteCount;
        bool won;
    }
    
    address public electionCommision;
    
    uint public votersCount;
    string public votingType;  // e.g. Presidential Election
    string public area; // e.g. Taiwan
    uint public votedCount;
    bool public complete;
    Candidate[] public candidates;
    uint mostVote;
    uint mostVoteCandidateIndex;
    mapping(address => bool) public voted;  // avoid double vote
    mapping(address=>bool) public voters;  // legal voters


    modifier onlyOwner() {
        require(msg.sender == electionCommision);
        _;
    }

    modifier onlyVoter() {
        require(voters[msg.sender]);
        _;
    }

    modifier beforeFinalization() {
        require(!complete);
        _;
    }

    function Ballot(string _votingType, string _area, address[] _candidates, address _electionCommision) public {
        electionCommision = _electionCommision;
        votersCount = 0;
        votingType = _votingType;
        area = _area;
        votedCount = 0;
        complete = false;
        for(uint i = 0; i<_candidates.length; i++){
            Candidate memory newCandidate = Candidate({
               candidateAddress: _candidates[i],
               name: '',
               voteCount: 0,
               won: false
            });
            candidates.push(newCandidate);
        }
        mostVote = 0;
        mostVoteCandidateIndex = candidates.length;

    }

    function setCandidateName(uint index, string name) public onlyOwner beforeFinalization {
        candidates[index].name = name;
    }

    function validatingVoters(address[] residents) public onlyOwner beforeFinalization {
        for(uint i = 0; i<residents.length; i++){
            if(!voters[residents[i]])
                votersCount++;
            voters[residents[i]] = true;
        }
    }

    function voteCandidate(uint index) public onlyVoter beforeFinalization {
        require(!voted[msg.sender]);
        voted[msg.sender] = true;
        candidates[index].voteCount++;
        if(candidates[index].voteCount > mostVote) {
            mostVote = candidates[index].voteCount;
            mostVoteCandidateIndex = index;
        }
        votedCount++;

    }

    function finalize() public onlyOwner beforeFinalization {
        candidates[mostVoteCandidateIndex].won = true;
        complete = true;
    }
}
