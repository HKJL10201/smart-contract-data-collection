// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Ballot {

    uint candidatesCount = 10;
    mapping(uint => string) candidates;
    mapping(uint => uint) votes;

    event VoteCasted(address voter, string votedFor);


    constructor(){
        candidates[1] = "John Doe";
        candidates[2] = "Ruja Ignatova";
        candidates[3] = "Satoshi Nakimoto";
        candidates[4] = "Battista Ahmed";
        candidates[5] = "Orpha Antonie";
        candidates[6] = "Bahadir Hadiyya";
        candidates[7] = "Aurora Yechezkel";
        candidates[8] = "Kotone Sylvia";
        candidates[9] = "Rakesh Nikolina";
        candidates[10] = "Per Olexiy";
    }

    function getCandidates() public view returns (string[] memory){
        string[] memory candidatesNames = new string[](candidatesCount);
        for (uint256 i = 1; i <= candidatesCount; i++) {
            candidatesNames[i-1] = candidates[i];
        }
        return candidatesNames;
    }

    function castVote(uint candidateNumber) public returns(bool valid) {
        votes[candidateNumber] = votes[candidateNumber]+1;

        emit VoteCasted(msg.sender, candidates[candidateNumber+1]);

        return true;
    }

    function getVotesPerCandidate(uint256 candidateNumber) public view returns (uint256 votesPerCandidate){
        return votes[candidateNumber];
    }

    function getAllVotes() public view  returns (uint[] memory) {
        uint[] memory allVotes = new uint[](candidatesCount);

        for (uint256 i = 0; i < candidatesCount; i++) {
            allVotes[i] = votes[i];
        }

        return allVotes;
    }
}