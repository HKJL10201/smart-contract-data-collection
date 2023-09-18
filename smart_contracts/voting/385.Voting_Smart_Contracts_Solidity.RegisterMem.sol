// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Member{
    address voter;
    bool b;
}

struct Register{
    address reg;
}

contract Mapping{

    Member[] voterInfoList;
    Register[] registrationList;
    address owner;
    bool votingStatus;
    mapping(address=>bool) hasVoted;
    mapping(address=>bool) hasRegistered;

    constructor(){
        owner = msg.sender;
    } 

    event VoteCasted(address voter,string s);
    function castVote(address electionMember) public {

        require(votingStatus == true);
        
        for(uint256 i=0; i<registrationList.length; i++){
            require(registrationList[i].reg != electionMember,"Member not found");
            // if(registrationList[i].reg != electionMember){      
            //     emit VoteCasted(electionMember, "You selected wrong member");
            //     revert("You selected wrong member");
            // }
        }
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

    function register() public{
        require(!hasRegistered[msg.sender],"Already registered");
        hasRegistered[msg.sender] = true;
        registrationList.push(Register(msg.sender));
    }
    function getRegistrationList() public view returns(Register[] memory){
        return registrationList;
    }
}
