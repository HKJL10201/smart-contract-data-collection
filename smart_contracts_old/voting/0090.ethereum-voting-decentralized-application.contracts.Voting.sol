pragma solidity ^0.5.0;

contract Voting {

struct voterData{
    uint id;
    string name;
    }
    
    voterData[] public voter;

    function set(uint _id, string memory _name) public {
        
        voter.length ++;
        voter[voter.length-1].id = _id;
        voter[voter.length-1].name  = _name;
    }

}
