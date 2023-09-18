pragma solidity >=0.4.22 <0.8.0;

contract Election {


    event VotedEvent (
        uint indexed _candidateId
    );

    struct Candidate {
        uint id ;
        string name;
        uint votes_count;
    }

    // store voters
    mapping(address => bool) public voters;
 

    // store canidate
    mapping(uint => Candidate) public candidates;
    uint public candidatesCount; 
    // write canidate
    function addCandidate(string memory _name ) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount,_name,0);
    }

    function vote (uint _candidate_id) public {
        require(voters[msg.sender] == false);
        require(_candidate_id >0 && _candidate_id <= candidatesCount);

        voters[msg.sender] = true;
        candidates[_candidate_id].votes_count ++;

        emit VotedEvent(_candidate_id);
    }


constructor () public {

             addCandidate("Candidate 1");
             addCandidate("Candidate 2");
        }



}
