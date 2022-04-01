// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.8.0;
pragma experimental ABIEncoderV2;

import "./ownable.sol";

contract ElectionFactory is Ownable {
    constructor () {
        listAdmin[owner] = true;
    }

    struct Election {
        string title;
        uint256 creationDate;
        uint closingDate;
        uint totalVoters;
        bool isOpen;

        uint candidatesCount;
        mapping (uint => Candidate) candidates;
        mapping (address => bool) voters;
        uint[] winners;
    }

    struct Candidate {
        string name;
        mapping (uint => uint) notes;
        uint percent;
        uint averageNote;
    }
    uint public electionsCount;
    mapping (uint => Election) public elections;

    mapping (uint => address) electionToOwner;
    mapping (address => uint) ownerElectionCount;
    mapping (address => bool) listAdmin;

    modifier isAdmin(address _userAddress) {
        require (listAdmin[_userAddress] == true, "You are not an admin");
        _;
    }

    function addAdmin(address _userAddress) external isAdmin(msg.sender) {
        listAdmin[_userAddress] = true;
    }

    function deleteAdmin(address _userAddress) external isAdmin(msg.sender) {
        require(msg.sender != owner, "Cannot remove owner from admins");
        listAdmin[_userAddress] = false;
    }

    function isUserAdmin(address userAddress) external view returns(bool){
        return listAdmin[userAddress];
    }

    function createElection(string memory _title, string[] memory _candidatesNames) external isAdmin(msg.sender) returns (uint) {
        uint nbCandidates = _candidatesNames.length;
        electionsCount++;
        Election storage election = elections[electionsCount];
        election.title = _title;
        election.creationDate = block.timestamp;
        election.totalVoters = 0;
        election.isOpen = true;

        for (uint i = 0; i < nbCandidates; i++) {
            addCandidate(electionsCount, _candidatesNames[i]);
        }

        electionToOwner[electionsCount] = msg.sender;

        ownerElectionCount[msg.sender] += 1;

        return electionsCount;
    }

    function addCandidate(uint _electionId, string memory _candidateName) public {
        elections[_electionId].candidates[elections[_electionId].candidatesCount++].name = _candidateName;
    }
}
