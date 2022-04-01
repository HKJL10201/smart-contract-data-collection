// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Election {
    // Election details
    string public name;
    string public description;

    // Struct of candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    mapping(address => bool) public voters;

    mapping(uint256 => Candidate) public candidates;

    uint256 public candidatesCount = 0;

    constructor(string[] memory _info, string[] memory _candidates) {
        require(_candidates.length > 0, "There should be atleast 1 candidates");
        name = _info[0];
        description = _info[1];
        for (uint256 i = 0; i < _candidates.length; i++) {
            addCandidate(_candidates[i]);
        }
    }

    function addCandidate(string memory _name) private {
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        candidatesCount++;
    }

    function vote(uint256 _candidateId) public {
        require(!voters[msg.sender], "Voter has already voted!");
        require(
            _candidateId >= 0 && _candidateId < candidatesCount,
            "Invalid candidate !!!"
        );

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
    }
}
