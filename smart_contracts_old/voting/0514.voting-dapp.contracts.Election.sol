pragma solidity >0.4.2 <0.6.0;

contract Election {
    // Constructor, with store and read candidate
    string public candidate;

    //Basic Candidate structure
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        // string partyName;
        // string adharNumber; 
        // can be a generic UUID which could corresponds to PAN, etc
    }

    //Fetch Candidate
    mapping(uint => Candidate) public candidates;

    // total number of Candidates
    uint public candidatesCount;

    constructor() public{
        addCondidate("BJP");
        addCondidate("Congress");
    }

    // add Condidate
    function addCondidate(string memory _name) private {
        candidatesCount ++;
        
        candidates[candidatesCount] = Candidate (candidatesCount, _name, 0);
    }


    //Voting part of the code:
    // Store accounts that have voted
    mapping(address => bool) public voters;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );

    function vote (uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }

}