pragma solidity ^0.4.2;

contract Election {
    // model of a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;

    }

    // store candidates
    // fetch candidate
    mapping(uint => Candidate) public candidates;   
    // a mapping in solidity is like an associative array (hash) key->uint(id) mapped with Candidate(name)

    // store candidate vote count
    uint public candidatesCount;
    /*
      any value not present within the mapping, when called for will return an empty candidate
      making it impossible to determine the size of the mapping
      hence we use candidatesCount
    */

    // store accounts that have voted
    mapping(address => bool) public voters;   

    // voted event
    event votedEvent(uint indexed _candidateId);

    constructor () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");

    }

    //function to add a candidate to the mapping
    function addCandidate(string _name) private {
        /*
        solidity follows the convention of naming local variable with a preceding underscore "_"
        */
        ++candidatesCount;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);

    }

    // increase the vote count of the specified candidate
    function vote(uint _candidateId) public {

        // require that the voter has not voted before
        require(!voters[msg.sender], "\n\n***\nPERMISSION DENIED: cannot cast multiple votes!!!\n***\n");

        // require that the candidate is valid
        require(_candidateId > 0 && _candidateId <= candidatesCount, "\n\n***\nERROR: Invalid candidate!!!\n***\n");

        //record that the voter has voted (using the metadata passed along the function call {msg})
        voters[msg.sender] = true;

        // update candidate vote count
        ++candidates[_candidateId].voteCount;
        
        //trigger voted event
        emit votedEvent(_candidateId);

    }

}