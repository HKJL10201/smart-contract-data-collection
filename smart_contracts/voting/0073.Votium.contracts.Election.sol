pragma solidity >=0.4.22 <0.8.0;

contract Election {

    //Model a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    //Store accounts that have voted
    mapping(address=>bool) public voters;
    //Store the candidate
    //Fetch Candidate
    mapping(uint=> Candidate) public candidates;
    //Store Candidate Count
    uint public candidatesCount;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );

    constructor () public{
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        //record that voter has voted

        require(!voters[msg.sender]);

        require(_candidateId > 0 && _candidateId <= candidatesCount);
        voters[msg.sender] = true;
        // update candidate vote count
        candidates[_candidateId].voteCount ++;

        emit votedEvent(_candidateId);
    }
}