pragma solidity ^0.4.2;

contract Election {
    //model a candidate
    struct Candidate{
        uint id;
        string name;
        uint voteCount;

    }
    //stor accounts that have voted
    mapping (address => bool) public voters;
    //store condidate
    //fetch candidate
    mapping (uint => Candidate) public candidates;
    //store candidates count
    uint public candidatesCount;
    //constructor


    //voted event
    event votedEvent(uint indexed _candidateId);

    function Election() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount,_name,0);
    }
    function vote(uint _candidateId) public{
        // require that they haven't voted before
        require(!voters[msg.sender]);

        //requier a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;
        // update candidate vote cout
        candidates[_candidateId].voteCount ++;

        votedEvent(_candidateId);
    }
}