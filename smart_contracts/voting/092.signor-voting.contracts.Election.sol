pragma solidity ^0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";



contract Election is Ownable {

    uint startTime;
    uint endTime;


    //registered voters
    mapping (address => bool) voters;
    uint public noVoters;

    //registered candidates (ids)
    mapping (bytes32 => bool) candidates;
    uint public noCandidates;

    //votes per candidate
    mapping (bytes32 => uint) voteCount;

    //voters that have already voted
    mapping (address => bool) voted;
    uint public votesReceived;


    constructor (uint _startTime, uint _endTime) public {
        require(_startTime < _endTime, "start time needs to be lower than end time");
        startTime = _startTime;
        endTime = _endTime;
    }

    modifier onlyVoter() {
        require(isVoter(msg.sender), "not a registered voter");
        _;
    }

    modifier votingOpen() {
        require(now >= startTime && now < endTime, "voting currently not open");
        _;
    }


    function addVoter(address _address) public onlyOwner {
        require (now < startTime, "election already started");
        if (!voters[_address]) {
            voters[_address] = true;
            noVoters++;
        }
    }


    function addVoters(address[] memory _voters) public onlyOwner {
        for (uint i = 0; i < _voters.length; i++) {
                addVoter(_voters[i]);
        }
    }

    function removeVoter(address _address) public onlyOwner {
        require (now < startTime, "election already started");
        voters[_address] = false;
    }

    function isVoter(address _address) public view returns(bool) {
        return voters[_address];
    }

    function addCandidate(bytes32 _candidate) public onlyOwner {
        require (now < startTime, "election already started");
        require (!candidates[_candidate], "candidate already exists");
        candidates[_candidate] = true;
        noCandidates++;
    }

    function removeCandidate(bytes32 _candidate) public onlyOwner {
        require (now < startTime, "election already started");
        require (candidates[_candidate], "candidate does not exist");
        candidates[_candidate] = false;
        noCandidates--;
    }

     function isCandidate(bytes32 _candidate) public view returns(bool) {
        return candidates[_candidate];
    }


    function getVotes(bytes32 _candidate) public view returns(uint) {
        return voteCount[_candidate];
    }
}