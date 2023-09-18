//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract Voting{
    struct Candidate{
        bytes32 name;
        uint votes;
        bool voted;
    }
    
    address owner;
    Candidate[] public Candidates;
    mapping(address => bool)public isVoted;


    constructor(){
     owner = msg.sender;
    }

    function CreateCandidate(bytes32 _name)external{
        require(msg.sender == owner, "You are not Owner");
        Candidates.push(
            Candidate({
                name:_name,
                votes:0,
                voted:false
            })
        );
    }

    function Vote(uint _index)external {
          require(!isVoted[msg.sender], "Already Voted !");
          isVoted[msg.sender] = true;
          Candidates[_index].votes += 1;
    }

    function getCandidate()public view returns(uint){
        return Candidates.length;
    }
}