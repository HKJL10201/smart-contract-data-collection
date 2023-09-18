// SPDX-License-Identifier:GPL-3.0

pragma solidity  ^0.8.17;

contract Leader{

    address public immutable owner;
    uint public noOfParticipants;

    struct Contestants{
        string name;
        uint id;
        address addr;
    }

    Contestants [] public participants;
    mapping(address => Contestants) public leaders;
    mapping(address => uint) public noOfLeaderVotes;

    // Event for Adding a Contestant
    event AdditionOfParticipant(address _owner, Contestants _newContestant);


    constructor(){
        owner = msg.sender;
        noOfParticipants = 0;
    }

    modifier onlyOwner(){
        require(owner==msg.sender);
        _;
    }

    function addParticipant(string memory _name, address _addr) external onlyOwner {
        // Only one address can be added for a person
        require(leaders[_addr].addr!=_addr,"Only one guy can add him/her");
        participants.push(Contestants(_name,participants.length,_addr));
        noOfLeaderVotes[_addr] = 0;
        leaders[_addr] = Contestants(_name,noOfParticipants,_addr);
        emit AdditionOfParticipant(owner,participants[noOfParticipants]);
        noOfParticipants = noOfParticipants +1;
    }

}







