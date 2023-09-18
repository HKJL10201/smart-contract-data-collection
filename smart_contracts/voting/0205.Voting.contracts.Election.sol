pragma solidity >=0.4.21 <0.7.0;

contract Election {
    struct Candidate {
        uint id;
        string name;
        uint vote;
    }
    
    uint candidate_count;
    mapping(address => bool) voted;
    mapping(uint => Candidate) public candidate_votes;

    constructor() public {
      add("Barack Obama");
      add("Joe Biden");
    }
    
    function add(string memory _name) private{
        candidate_count++;
        candidate_votes[candidate_count] = Candidate(candidate_count, _name, 0);
    }
    
    function vote(uint id) external check_vote {
        candidate_votes[id].vote += 1;
        voted[msg.sender] = true;
    }
    
    modifier check_vote {
        require(!voted[msg.sender], "You already voted");
        _;
    }
}