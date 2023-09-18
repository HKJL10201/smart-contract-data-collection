pragma solidity >=0.4.22 <0.8.0;
import "./Ownable.sol";
contract Election  is Ownable {
    constructor () public {
        addCandidate("Can 1");
        addCandidate("Can 2");
    }

    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }

    mapping (address => bool) public hasVoted;
    mapping (uint => Candidate) public candidates;
    mapping (uint => uint) votes;
    uint public candidatesCount ;
    
    function addCandidate(string memory _name) private onlyOwner {
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0); 
        candidatesCount++;
    }

    function candidateOneVotes() public view returns (uint) {
      return votes[0];
    }

    function candidateTwoVotes() public view returns (uint) {
      return votes[1];
    }

    function vote (uint _candidateId) public{
      require(hasVoted[msg.sender] == false);
      hasVoted[msg.sender] = true;
      votes[_candidateId] += 1;
    }   
   
    
}
