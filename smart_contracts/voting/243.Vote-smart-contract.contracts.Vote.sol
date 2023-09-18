// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract Vote {
    address public owner; // user who created this contract
    address[] private votedUsers; // list of users who have already voted
    mapping(address => uint256) private candidateVotes; // cadidate => number of votes
    address[] private candidtesAddress;// list of all condidates
    // address winner;
    uint256 winnerVotes;

    constructor(address[] memory candidates) {
        owner = msg.sender; // owner of this contract
        // winner = address(0);
        winnerVotes = 0;
        candidtesAddress = candidates;
        for (uint256 i = 0; i < candidates.length; i++)
            candidateVotes[candidates[i]] = 0;
    }

    /**
        return true if the "candidate" is present in candidtesAddress array
     */
    function isCandidate(address candidate) public view returns (int) {
        for (uint256 i = 0; i < candidtesAddress.length; i++)
            if (candidate == candidtesAddress[i])
                return 1;
        return 0;
    }

    /**
        Gives list of all the candidatesn eligible for voting
    */
    function getAllCandidates() public view returns(address[] memory) {
        return candidtesAddress;
    }

    function vote(address candidate) public {
        for (uint256 i = 0; i < votedUsers.length; i++)
            if (votedUsers[i] == msg.sender)
                return;
        votedUsers.push(msg.sender);
        candidateVotes[candidate]++;
        
        winnerVotes = candidateVotes[candidate] > winnerVotes ? candidateVotes[candidate] : winnerVotes;
    }
    
    // function getVoteCount(address candidate) public view returns(uint256) {
    //     return candidateVotes[candidate];
    // }

    function getWinner() public view returns (address[] memory) {
        address[] memory result = new address[](candidtesAddress.length);
        uint256 j = 0;
        for(uint256 i = 0 ; i < candidtesAddress.length ; i++) {
            if(candidateVotes[candidtesAddress[i]] == winnerVotes) {
                result[j] = candidtesAddress[i];
                j++;
            }
        }
        
        return result;
    }

    function hasVoted() public view returns (bool) {
        for (uint256 i = 0; i < votedUsers.length; i++)
            if (votedUsers[i] == msg.sender)
                return true;
        return false;
    }
}
