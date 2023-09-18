// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Election {
    address public owner; // person who deployed contract
    string public electionTitle;

    constructor(string memory title) {
        owner = msg.sender;
        electionTitle = title;
    }

    struct Candidate {
        string name;
        uint256 votesNumber;
    }

    struct Voter {
        address addr;
        bool exist;
        bool alreadyVoted;
    }

    Candidate[] public candidates;
    address[] public votersAddresses;

    mapping(address => Voter) public voters;

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    // main functionality
    function authorizeVoter(address voterAddress) public ownerOnly() {
        require(voters[voterAddress].exist == false);

        voters[voterAddress] = Voter(voterAddress, true, false);
        votersAddresses.push(voterAddress);
    }

    function addCandidate(string memory candidateName) public ownerOnly() {
        candidates.push(
            Candidate(candidateName, 0)
        );
    }

    function vote(uint256 candidateID) public {
        require(voters[msg.sender].exist == true);
        require(voters[msg.sender].alreadyVoted == false);

        voters[msg.sender].alreadyVoted = true;
        candidates[candidateID].votesNumber += 1;
    }


    // support funcs
    function getAllCandidates() public view returns(Candidate[] memory) {
        return candidates;
    }

    function getAllVoters() public view returns(address[] memory) {
        return votersAddresses;
    }
}