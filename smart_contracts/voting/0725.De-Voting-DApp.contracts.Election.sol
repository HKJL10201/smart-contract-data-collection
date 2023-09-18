pragma solidity >=0.4.22 <0.8.0;

contract Election {
    struct Candidate {                              // model of a candidate
        uint id;
        string name;
        uint voteCount;
    }

    mapping(address => bool) public voters;         // mapping of voters to their vote status
    mapping(uint => Candidate) public candidates;   // mapping of candidate objects with their id
    uint public candidatesCount;                    // count of the total candidates

                                                    // voting event
    event votedEvent (                            
        uint indexed _candidateId
    );

    constructor () public {                         // adding candidates while deploying
        addCandidate("Candidate A");
        addCandidate("Candidate B");
        addCandidate("NOTA");

    }

    function addCandidate (string memory _name) private {                           // function to add candidate
        candidatesCount ++;

        // if (candidatesCount == 2) {                                                 // for testing
        //     candidates[candidatesCount] = Candidate(candidatesCount, _name, 2);
        //     return;
        // }

        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);         // initializing all candidates with 0 votes
    }

    function vote (uint _candidateId) public {                                      // function to vote

        require(!voters[msg.sender]);                                               // checking if the voter has already voted
        require(_candidateId > 0 && _candidateId <= candidatesCount);               // requires a valid candidate

        voters[msg.sender] = true;                                                  // marking voter's status as voted

        candidates[_candidateId].voteCount ++;                                      // adding the vote to the candidate

        emit votedEvent(_candidateId);                                              // triggering the voting event
    }
}
