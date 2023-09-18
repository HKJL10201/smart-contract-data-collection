// SPDX-License-Identifier: GPL-3.0

  pragma solidity >=0.5.0<0.9.0;

contract VoteContract{
    address public owner;
    mapping(uint256 => uint256) votes;
    function Vote(uint256 index) public returns(bool){
        votes[index]+=1;

        return true;
    }

    function transferOwnership(address _new) public returns (bool){
     require(msg.sender==owner, "Only Owner Can manipulate");
     owner = _new;
     return true;
    }

    constructor(){
        owner = msg.sender;
    }

    function getVotes(uint256 index) public view returns(uint256){
        return votes[index];
    }

    function setNull() public returns (bool){
         require(msg.sender==owner, "Only Owner Can manipulate");
         votes[0] = 0;
         votes[1] = 0;
         votes[2] = 0;
         votes[3] = 0;
         return true;
    }
}