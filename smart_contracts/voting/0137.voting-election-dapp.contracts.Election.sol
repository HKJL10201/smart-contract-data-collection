// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Election {
    struct Candidate {
        uint256 id;
        string name;
        uint256 votecount;
    }
    uint256 public candidatesCount;
    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public votedornot;

    event electionupdated(uint256 id, string name, uint256 votecount);
    event addcandidate(string name);

    // constructor() public {
    //     addCandidate("joko widodo");
    //     addCandidate("prabowo subianto");
    // }

    function addCandidate(string memory name) public {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, name, 0);

        emit addcandidate(candidates[candidatesCount].name);
    }

    function Vote(uint256 _candidateId) public {
        //the person has not voted again
        require(!votedornot[msg.sender], "kamu telah memilih");
        //the id that the person has input is available
        require(
            candidates[_candidateId].id > 0 && _candidateId <= candidatesCount,
            "id tidak ditemukan"
        );
        //pemilih bertambah
        candidates[_candidateId].votecount += 1;
        //bool true
        votedornot[msg.sender] = true;
        emit electionupdated(
            _candidateId,
            candidates[_candidateId].name,
            candidates[_candidateId].votecount
        );
    }
}
