// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Simple voting contract
contract Voting {
    struct Candidate {
        address addr;
        uint votes;
    }

    Candidate[] public candidates;
    mapping(address => bool) public voted;

    event Join(address candidate);
    event Vote(address voter, address candidate);

    /// @notice Join the voting as a candidate
    function participate() external {
        require(!isCandidate(msg.sender), "You are already a candidate");
        candidates.push(Candidate(msg.sender, 0));

        emit Join(msg.sender);
    }

    /// @notice Vote for some candidate
    /// @param candidateAddress Address of your candidate
    function vote(address candidateAddress) external {
        require(msg.sender != candidateAddress, "You can not vote for yourself");
        require(!voted[msg.sender], "You have already voted");

        (bool exists, uint index) = findCandidate(candidateAddress);
        require(exists, "There is no candidate with such the address");

        voted[msg.sender] = true;
        candidates[index].votes = candidates[index].votes + 1;

        emit Vote(msg.sender, candidateAddress);
    }

    /// @notice Getter for a candidate list
    /// @return List of all candidates
    function getAllCandidates() public view returns (Candidate[] memory) {
//        Candidate[] memory candidatesArray = new Candidate[](candidates.length);
//        for (uint i = 0; i < candidates.length; ++i) {
//            Candidate storage candidate = candidates[i];
//            candidatesArray[i] = candidate;
//        }
        return candidates;
    }

    /// @notice Check if the address is already a candidate
    /// @param addr Checking address
    /// @return True if the address is a candidate else false
    function isCandidate(address addr) public view returns (bool) {
        for (uint i = 0; i < candidates.length; ++i) {
            if (candidates[i].addr == addr) {
                return true;
            }
        }
        return false;
    }

    /// @notice Look for a candidate with given address
    /// @param addr Checking address
    /// @return True if found else false
    /// @return Index of the candidate or array length if not found
    function findCandidate(address addr) public view returns (bool, uint) {
        for (uint i = 0; i < candidates.length; ++i) {
            if (candidates[i].addr == addr) {
                return (true, i);
            }
        }
        return (false, candidates.length);
    }
}
