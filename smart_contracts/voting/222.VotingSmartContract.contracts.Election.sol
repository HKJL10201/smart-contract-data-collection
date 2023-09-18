pragma solidity ^0.4.11;

contract Election {
    //candidate model
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store voter accounts
    // Returns true if voter already recorded as voted
    mapping(address => bool) public voters;
    // Store candidate
    mapping(uint => Candidate) public candidates;
    // store candidate count
    uint public candidatesCount;

    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function Election () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function vote (uint _candidateId) public {
        // Fuction allows _candidate input and metadata
        // app.vote(<CandidateID>, {from: web3.eth.accounts[<account number>] })
        // eg:-  app.vote(1, { from: web3.eth.accounts[0]})

        // check voter and input valid
        // require that they haven't voted before
        require(!voters[msg.sender]);
        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        // msg.sender provides defaultly with public function which represents address which called the function
        // Set account true when voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;
    }
}
