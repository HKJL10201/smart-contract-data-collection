pragma solidity ^0.4.24;

contract Election {
   // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    bool votingClosed;
    address passportDB;
    // contract owner
	address owner;
    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Read/write candidates
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;

    constructor (address _passportDB) public {
    	owner = msg.sender;
        passportDB = _passportDB;
        votingClosed = false;
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate (string _name) public {
    	require(owner == msg.sender, "Sender not authorized. Please contact contact owner for adding new candidates.");
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function closeVoting() public {
        require(owner == msg.sender, "Only owner can close voting");
        require(!votingClosed, "Voting is already closed");
        votingClosed = true;
    }

    function vote (uint _candidateId) public {
        // require that voter provided his passport info
        require(Passport(passportDB).voterIsRegistered(msg.sender), "No passport info provided by voter");
        // require that they haven't voted before
        require(!voters[msg.sender]);
        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        // voting is closed
        require(!votingClosed, "Sorry but voting is closed");

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;
    }
}

contract Passport {
    function voterIsRegistered (address voterAddress) public view returns (bool);
}