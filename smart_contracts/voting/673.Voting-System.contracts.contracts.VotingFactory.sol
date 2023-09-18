// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./VotingSystem.sol";

contract VotingFactory{
    
    address payable adminstrator;
    votingSystem[] public deployedElections;
    constructor(){
        adminstrator = payable(msg.sender);
    }
    function createElection(string memory _name, uint8 _level, uint8 _electionType) public returns (address) {
        // removing the adminstrator check for now > anyone can create an election
        // require(msg.sender == adminstrator, "Only admin can create an election");
        votingSystem newElection = new votingSystem(_name,_level,_electionType,payable(msg.sender));
        deployedElections.push(newElection);
        return address(newElection);
    }

    function getDeployedElections() public view returns (votingSystem[] memory){
        return deployedElections;
    }
    
}