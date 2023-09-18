// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ballot {
    struct Voter {
        uint256 voterId;
        bool voted;
    }

    struct Candidate {
        uint256 candidateId;
        string name;
        uint256 voteTally;
    }

    mapping(address => bool) public voters;
    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public excludedAddresses;

    uint256 public candidatesCount;

    uint256 public length;

    string public proposalName;

    address public chairperson;

    constructor(
        string[] memory _candidateNames,
        string memory _proposalName,
        address[] memory _candidateAddresses
    ) {
        chairperson = msg.sender;
        proposalName = _proposalName;
        length = _candidateNames.length;

        for (uint256 i = 0; i < _candidateNames.length; i++) {
            addCandidate(_candidateNames[i]);
        }

        for (uint256 i = 0; i < _candidateAddresses.length; i++) {
            addCandidateAddress(_candidateAddresses[i]);
        }

        addCandidateAddress(msg.sender);
    }

    function addCandidateAddress(address _address) public {
        excludedAddresses[_address] = true;
    }

    function addCandidate(string memory _name) public {
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        candidatesCount++;
    }

    function getCandidates()
        external
        view
        returns (
            string[] memory,
            uint256[] memory,
            string memory
        )
    {
        string[] memory names = new string[](candidatesCount);
        uint256[] memory voteCounts = new uint256[](candidatesCount);
        for (uint256 i = 0; i < candidatesCount; i++) {
            names[i] = candidates[i].name;
            voteCounts[i] = candidates[i].voteTally;
        }
        return (names, voteCounts, proposalName);
    }

    function vote(uint256 _candidateId) public {
        require(!excludedAddresses[msg.sender]);
        require(!voters[msg.sender]);
        require(_candidateId >= 0 && _candidateId < candidatesCount);

        voters[msg.sender] = true;
        candidates[_candidateId].voteTally++;
    }

    function getCandidatesCount() public view returns (uint256) {
        return candidatesCount;
    }

    function getLength() public view returns (uint256) {
        return length;
    }

    function getProposalName() public view returns (string memory) {
        return proposalName;
    }

    function readVoteTally(uint256 _candidateId)
        external
        view
        returns (uint256)
    {
        return candidates[_candidateId].voteTally;
    }
}
