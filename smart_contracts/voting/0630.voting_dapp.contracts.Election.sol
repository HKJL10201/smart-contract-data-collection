// SPDX-License-Identifier: AGPL-1.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Election is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping (uint => Candidate) public candidates;
    mapping (address => bool) public voters;

    uint public candidatesCount;

    event votedEvent (
        uint indexed _candidateId
    );

    event addCandidateEvent (
        uint indexed candidatesCount
    );


    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    function addCandidate(string memory _name) public onlyOwner {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        emit addCandidateEvent(candidatesCount);
    }

    function vote(uint _candidateId) public {
        require(!voters[msg.sender], "Voters can only vote once.");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Candidate ID must exist.");
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount ++;
        emit votedEvent(_candidateId);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
