// Create a dapp for voting where all of the votes and candidate 
// registration happens on chain. Allow anyone to start an election 
// with a registration period, voting period, and ending time. 
// Allow anyone to sign up as a candidate during the registration
// period, and allow anyone to vote once during the voting period. 
// Create a front end where voters can see the results and know 
// how long is left in the election.


pragma solidity 0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";



contract VotingDapp {

    using Counters for Counters.Counter;
    Counters.Counter public electionId;
    
    enum Status {
        Registration,
        Voting,
        Ended
    }
    struct Candidate {
        string _name;
        address _address;
        uint _votes;
   
    }

    
    struct Election {
        string name;
        uint registrationEnd;
        uint voteEnd;
        Candidate[] candidates;
        Status electionStatus;
        Candidate[] winners;
        
    }

    string public name;
    
    mapping(uint => mapping(address => bool)) IdToaddressRegistered;
    mapping(uint => mapping(address => bool)) IdToaddressVoted;
    mapping(uint => Election) public idToElection;
    
    event ElectionCreated(uint Id, string Name, uint RegistrationEnd, uint VotingEnd, Status ElectionStatus);
    event CandidateRegistered(uint Id, Candidate[] Candidates);
    event VoteSubmitted(address Voter, Candidate[] Candidates, Status ElectionStatus);
    event ElectionResults(string Name, Candidate[] Candidates, Status ElectionStatus, Candidate[] Winners);

    
    constructor() {
        name = "Voting Dapp";
        
    }
    
    function createElection(string memory _name, uint registerPeriodInMinutes, uint votePeriodInMinutes) public {
        electionId.increment();
        uint _id = electionId.current();
        uint _registerEnd = block.timestamp + (registerPeriodInMinutes * 60);
        uint _voteEnd = _registerEnd + (votePeriodInMinutes * 60);
        idToElection[_id].name = _name;
        idToElection[_id].registrationEnd = _registerEnd;
        idToElection[_id].voteEnd = _voteEnd;
        idToElection[_id].electionStatus = Status(0);
        emit ElectionCreated(_id, _name, _registerEnd, _voteEnd, Status(0));

        
    }
    
    function registerCandidate(uint _id, string memory _name) public {
        require(block.timestamp <= idToElection[_id].registrationEnd, "Registration period has ended.");
        require(IdToaddressRegistered[_id][msg.sender] == false, "This address already registered.");
        IdToaddressRegistered[_id][msg.sender] = true;
        Candidate memory candidate = Candidate(_name, msg.sender, 0);
        idToElection[_id].candidates.push(candidate);
        emit CandidateRegistered(_id, idToElection[_id].candidates);
        
        
    }
    
    function seeCandidate(uint _id) public view returns(Candidate[] memory) {
        return idToElection[_id].candidates;
    }
    
    function vote(uint _id, string memory _name) public {
        require(block.timestamp >= idToElection[_id].registrationEnd, "Voting period hasn't started yet.");
        require(block.timestamp <= idToElection[_id].voteEnd, "Voting period has ended.");
        require(IdToaddressVoted[_id][msg.sender] == false, "This address already voted.");
        require(IdToaddressRegistered[_id][msg.sender] == false, "Candidates can't vote.");
        IdToaddressVoted[_id][msg.sender] = true;
        idToElection[_id].electionStatus = Status(1);
        Candidate[] memory candidates = idToElection[_id].candidates;
        for(uint i=0; i<candidates.length; i++) {
            if(keccak256(bytes(candidates[i]._name)) == keccak256(bytes(_name))){
                candidates[i]._votes = candidates[i]._votes + 1;
                idToElection[_id].candidates[i] = candidates[i];
                emit VoteSubmitted(msg.sender, candidates, Status(1));
            }
        }
        
   
    }
    
    function results(uint _id) public {
        require(block.timestamp >= idToElection[_id].voteEnd, "Voting period hasn't ended.");
        Election storage currentElection = idToElection[_id];
        Candidate[] memory candidates = currentElection.candidates; 
        uint winningVotes = 0;
        for(uint i=0; i < candidates.length; i++){
            if(candidates[i]._votes > winningVotes) {
                winningVotes = candidates[i]._votes;
            }
        }
        for(uint i=0; i < candidates.length; i++){
            if(candidates[i]._votes == winningVotes) {
                idToElection[_id].winners.push(candidates[i]);
            }
        }
        idToElection[_id].electionStatus = Status(2);
        // idToElection[_id] = currentElection;
        emit ElectionResults(currentElection.name, currentElection.candidates, Status(2), currentElection.winners);
    }
}






