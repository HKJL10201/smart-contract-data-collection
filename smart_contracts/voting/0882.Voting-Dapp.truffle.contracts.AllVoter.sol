// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract AllVoter{
    struct Voter{
        string id;
        string name;
        //Other info if needed;
    }

    address private immutable Owner;
    uint public numberOfVoter;

    mapping(address=>Voter) public voters;
    string[] public ids; 


    event NewVoterEvent(address indexed addr, string indexed id);

    constructor(){
        Owner = msg.sender;
    }
    
    function addVoter(address _voter, string memory _id) external {
        require(Owner == msg.sender, 'You are not allowed.');
        for(uint i; i<numberOfVoter; i++){
            string memory id = ids[i];
            if(keccak256(abi.encodePacked(id)) == keccak256(abi.encodePacked(_id))){
                revert('Voter already exist.');
            } 
        }
        //Checking for the voter's address already connected with a voter
        require(keccak256(abi.encodePacked(voters[_voter].id)) == keccak256(abi.encodePacked("")), 'Voter already exist.');

        Voter storage voter = voters[_voter];

        voter.id = _id;
        ids.push(_id);
        numberOfVoter = numberOfVoter + 1;

        emit NewVoterEvent(_voter, _id);

    }

    function getNID() public view returns(string memory NID){
        Voter storage voter = voters[msg.sender];
        NID = voter.id;
    }
}