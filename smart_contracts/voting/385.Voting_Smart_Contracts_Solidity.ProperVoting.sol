// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./OwnerShip.sol";

struct Member{
    address addr;
    uint256 voteCount;
}

contract EVoting is Ownable{

   
    Member[] public memberList;
    bool public isVoting;
    mapping(address=>bool) public hasVoted;
    mapping(address=>bool) public hasRegistered;
    event VoteCasted(address voter,string s);
    event Registered(address member);

    function castVoteForMember(address _member) public {

        require(isVoting, "Voting has not started");
        bool found;
        
        for(uint256 i=0; i<memberList.length; i++){
            
            if(memberList[i].addr == _member){
                require(!hasVoted[msg.sender], "already voted");
                hasVoted[msg.sender] = true;
                memberList[i].voteCount += 1;
                found = true;
                break;
            }

        }
        require(found, "Member not found");
        emit VoteCasted(msg.sender, "Voting complete");
        
    }

    function setVotingTo(bool _isVoting) public onlyOwner{
        // require(msg.sender == owner, "Unauthorised");
        isVoting = _isVoting;
    }

    function register(address _member) public onlyOwner{
        // require(msg.sender == owner, "Unauthorised");
        require(!hasRegistered[_member],"Already registered");
        hasRegistered[_member] = true;
        memberList.push(Member(_member,0));
        emit Registered(_member);
    }

// Only address return not voteCount
    // function getRegistrationList() public view returns(Member[] memory){
    //     return memberList;
    // }

    function getRegistrationList() public view returns(address[] memory){
        address[] memory memberAddress = new address[](memberList.length);
        for(uint i = 0; i<memberList.length; i++){
            memberAddress[i] = memberList[i].addr;    
        }
        return memberAddress;
    }
    

    
    function Winner() public view returns(address, uint256) {
        uint256 _voteCount;
        address memberAddress;
        require(isVoting == false, "Election not ended yet");
        for(uint i=0; i < memberList.length; i++){
            if(_voteCount < memberList[i].voteCount){
                _voteCount = memberList[i].voteCount;
                memberAddress = memberList[i].addr;
            }
        }
        return (memberAddress, _voteCount);
    }

    function deRegister(address _deReg) public onlyOwner{
        // require(msg.sender == owner, "Unauthorised");
        for(uint256 i=0; i<memberList.length; i++){
            if(memberList[i].addr == _deReg){
            delete memberList[i];
            hasRegistered[_deReg] = false;
            }
        }
    } 
}
