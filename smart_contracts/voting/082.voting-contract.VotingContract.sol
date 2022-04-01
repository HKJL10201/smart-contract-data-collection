// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Voiting {
    address owener;
    uint256 public CondidateCount;

    struct Condidate {
        uint256 id;
        string name;
        uint128 voteCount;
    }

    mapping(uint256 => Condidate) public candidates;
    mapping(address => bool) voted;

    constructor() public {
        owener = msg.sender;
    }

    function addCandidate(string memory _name) public returns (string memory) {
        require(msg.sender == owener, "Only owner can add candidate");
        CondidateCount++;
        candidates[CondidateCount] = Condidate(CondidateCount, _name, 0);
        return "Candidate added";
    }

    function vote(uint256 id) public returns (string memory) {
        require(id <= CondidateCount && id > 0, " Candidate not found");
        require(!voted[msg.sender], "You have already voted");
        candidates[id].voteCount++;
        voted[msg.sender] = true;
        return "Voted";
    }

    function voitingResult() public view returns (string memory) {
        uint256 winnerID = 0;
        uint256 winnerCount = 0;

        for (uint256 i = 1; i <= CondidateCount; i++) {
            if (candidates[i].voteCount > winnerCount) {
                winnerID = i;
                winnerCount = candidates[i].voteCount;
            }
        }
        return candidates[winnerID].name;
    }
}
