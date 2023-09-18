// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.6.0 <0.9.0;

contract Election {
    struct Candidate {
        string name;
        uint256 numVotes;
    }

    struct Voter {
        string name;
        bool authorished;
        uint whom;
        bool voted;
    }

    address public owner;
    string public electionName;
    mapping(address => Voter) public voters;
    Candidate[] public candidate;
    uint public totalVotes;

    modifier owerOnly() {
        require(msg.sender == owner);
        _;
    }

    function startElction(string memory _electionName) public {
        owner = msg.sender;
        electionName = _electionName;
    }

    function addCandidate(string memory _candidateName) public owerOnly {
        candidate.push(Candidate(_candidateName, 0));
    }

    function authorizedVoter(address _voterAddress) public owerOnly {
        voters[_voterAddress].authorished = true;
    }

    function getNumCandidate() public view returns (uint) {
        return candidate.length;
    }

    function vote(uint256 candidateIndex) public {
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorished);
        voters[msg.sender].whom = candidateIndex;
        voters[msg.sender].voted = true;
        candidate[candidateIndex].numVotes++;
        totalVotes++;
    }
}
