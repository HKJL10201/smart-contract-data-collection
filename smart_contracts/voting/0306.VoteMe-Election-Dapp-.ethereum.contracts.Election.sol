pragma solidity ^0.4.17;

contract ElectionFactory {
    address[] public deployedElections;

    function deployElection(uint _registrationPeriod, uint _votingPeriod) public {
        Election newElection = new Election(_registrationPeriod, _votingPeriod, msg.sender);
        deployedElections.push(address(newElection));
    }

    function getDeployedElections() public view returns (address[]) {
        return deployedElections;
    }
}

contract Election {
    struct Profile {
        string name;
        string slogan;
        address candidateAddress;
        uint votes;
        uint id;
    }
    Profile[] public profiles;
    uint public registrationPeriod;
    uint public votingPeriod;
    uint public creationTime;
    uint public votingStartTime;
    uint public maxVote;
    uint public candidateID;
    uint[] public winners;
    bool public startVote;
    bool public endVote;
    address public manager;
    mapping(address => bool) public voters;
    mapping(address => bool) public candidates;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function Election(uint _registrationPeriod, uint _votingPeriod, address deployer) public {
        manager = deployer;
        registrationPeriod = _registrationPeriod;
        votingPeriod = _votingPeriod;
        creationTime = block.timestamp;
        candidateID = 0;
    }

    function signAsCandidate(string name, string slogan) public {
        require(block.timestamp < (creationTime + registrationPeriod));
        require(!candidates[msg.sender]);
        Profile memory newProfile = Profile({
           name: name,
           slogan: slogan,
           candidateAddress: msg.sender,
           votes: 0,
           id: candidateID
        });

        profiles.push(newProfile);
        candidates[msg.sender] = true;
        candidateID++;
    }

    function startVoting() public restricted {
        require(block.timestamp > (creationTime + registrationPeriod));
        startVote = true;
        votingStartTime = block.timestamp;
    }

    function Vote(uint index) public {
        Profile storage profile = profiles[index];
        require(block.timestamp < (votingStartTime + votingPeriod));
        require(!voters[msg.sender]);

        voters[msg.sender] = true;
        profile.votes++;

        if (profile.votes > maxVote) {
            maxVote=profile.votes;
            winners = new uint[](0);
            winners.push(profile.id);
        }

        else if (profile.votes == maxVote) {
            winners.push(profile.id);
        }
    }

    function declareResult() public {
        require(block.timestamp > (votingStartTime + votingPeriod));
        endVote = true;
    }

    function getWinners() public view returns (uint[]) {
        return winners;
    }

    function getNumberOfWinners() public view returns (uint) {
        return winners.length;
    }

    function getNumberOfCandidates() public view returns (uint) {
        return profiles.length;
    }
}