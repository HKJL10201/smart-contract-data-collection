// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

contract Voting {
    struct Candidate {
        address candidateAddress;
        string candidateName;
        string candidatePromise;
        string photoUrl;
        uint256 votingCount;
    }

    //Voters identity shouldn't be tracked
    mapping(address => bool) public voters;
    uint256 public votingCount;
    Candidate[] public candidates;

    event VoteOccurs(uint256 votingCount, Candidate[] candidates);

    modifier singleVote() {
        require(voters[msg.sender] == false, "You can't vote twice.");
        _;
    }

    constructor() {}

    function vote(uint256 candidateIndex) public payable singleVote {
        Candidate storage candidate = candidates[candidateIndex];
        candidate.votingCount += 1;
        votingCount += 1;
        voters[msg.sender] = true;
        emit VoteOccurs(votingCount, candidates);
    }

    function becomeCandidate(
        string memory candidateName,
        string memory candidatePromise,
        string memory photoUrl
    ) public {
        Candidate memory candidate = Candidate({
            candidateName: candidateName,
            candidateAddress: msg.sender,
            candidatePromise: candidatePromise,
            photoUrl: photoUrl,
            votingCount: 0
        });
        candidates.push(candidate);
    }

    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }
}
