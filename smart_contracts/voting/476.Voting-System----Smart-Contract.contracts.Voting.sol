// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Voting {
    address public organizer;
    uint256 votingPeriod;
    uint256 candidateCount;

    address[] public candidateAddresses;

    constructor() {
        organizer = msg.sender;
        votingPeriod = block.timestamp + 180;
    }

    struct electionCandidate {
        string name;
        string party;
        uint256 age;
        uint256 votes;
    }

    struct Voter {
        string name;
        uint256 age;
    }

    mapping(address => electionCandidate) candidates;
    mapping(address => Voter) votersList;
    mapping(address => bool) hasVoted;

    modifier onlyOrganizer() {
        require(
            msg.sender == organizer,
            "Only the organiser can register candidates"
        );
        _;
    }

    function registerVoter(string memory _name, uint256 _age) public {
        require(_age >= 18, "You are not eligible to vote");
        require(votersList[msg.sender].age == 0, "You are already registered");

        Voter memory newVoter = Voter(_name, _age);
        votersList[msg.sender] = newVoter;
    }

    function registerCandidate(
        address _candidateAddress,
        string memory _name,
        string memory _party,
        uint256 _age
    ) public onlyOrganizer {
        electionCandidate memory candidate = electionCandidate({
            name: _name,
            party: _party,
            age: _age,
            votes: 0
        });

        candidates[_candidateAddress] = candidate;
        candidateAddresses.push(_candidateAddress);
        candidateCount++;
    }

    function getCandidateAddresses() public view returns (address[] memory) {
        return candidateAddresses;
    }

    function castVote(address _candidateAddress) public {
        require(block.timestamp < votingPeriod);
        require(votersList[msg.sender].age != 0, "You are not a voter");
        require(hasVoted[msg.sender] == false, "You have already voted");

        candidates[_candidateAddress].votes += 1;
        hasVoted[msg.sender] = true;
    }

    function selectWinner() public view onlyOrganizer returns (address) {
        require(
            block.timestamp >= votingPeriod,
            "Voting period has not ended yet"
        );

        address winner;
        uint256 highestVotes = 0;

        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            address candidateAddress = candidateAddresses[i];
            uint256 candidateVotes = candidates[candidateAddress].votes;

            if (candidateVotes > highestVotes) {
                highestVotes = candidateVotes;
                winner = candidateAddress;
            }
        }

        require(winner != address(0), "No winner found");

        return winner;
    }
}