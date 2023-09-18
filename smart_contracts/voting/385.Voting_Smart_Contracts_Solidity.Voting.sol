// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Member{
    address voter;
    bool b;
}


contract Mapping{

    Member[] voterInfoList;
    address owner;
    bool votingStatus;
    mapping(address=>bool) hasVoted;
   
    constructor(){
        owner = msg.sender;
    } 

    event VoteCasted(address voter,string s);
    function castVote() public {
    //     if(hasVoted[msg.sender]) {         // method 1
    //  revert("already voted");   
    // }
    // require(hasVoted[msg.sender]!=true,"already voted");        // method 2
        require(votingStatus==true);
        require(!hasVoted[msg.sender],"already voted");
        hasVoted[msg.sender] = true;
        voterInfoList.push(Member(msg.sender,true));
        emit VoteCasted(msg.sender,"Voting complete");
    
    }
    function getVoterInfoList() public view returns(Member[] memory){
        return voterInfoList;
    }
    function totalVotes() public view returns(uint256 count){
        return voterInfoList.length;
    }

    function votingTime(bool _status) public {
        require(msg.sender == owner);
        votingStatus = _status;
    }


    function currentVotingStatus() public view returns(string memory voteStartStop){
        if(votingStatus==true){
            voteStartStop = "Voting is started";
            return voteStartStop;
        }else{
            voteStartStop = "Voting is stoped";    
            return voteStartStop;
            
        }
    }
}
