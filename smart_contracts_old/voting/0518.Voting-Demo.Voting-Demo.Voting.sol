pragma solidity ^0.5.0;
contract Voting {
    
    struct Candidate {
        string name;
        uint votecount;
    }
    
    struct Voter {
        bool voted;
    }
    
    mapping(address => Voter) public voters;    //记录该用户是否投过票
    
    Candidate[] public candidates;
    
    constructor() public {
        candidates.push(Candidate({name:"Tom",votecount:0}));
        candidates.push(Candidate({name:"Jerry",votecount:0}));
    }
    
    function Vote(uint8 candidate_num) public{  //自带返回值，返回值是txhash
        if(voters[msg.sender].voted || candidate_num>candidates.length)
        return;
        candidates[candidate_num].votecount += 1;
        voters[msg.sender].voted = true;
    }
    
    //显示所有候选人和得票
    function getCount(uint i) public view returns(string memory, uint){
        return(candidates[i].name,candidates[i].votecount);
    }
    
    //显示候选人数量
    function getCountNumber() public view returns(uint){
        return (candidates.length);
    }
    
    //增加候选人
    function addCandidate(string memory _name) public {
        candidates.push(Candidate({name:_name,votecount:0}));
    }
    
}