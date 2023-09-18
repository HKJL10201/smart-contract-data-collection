// SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

contract votingSystem{
    
    address public organiser;
    uint time;

    struct voterCheck{
        address voterAddress;
        bool voted;
    }

    voterCheck[] public voterList;

    mapping (address => voterCheck) public voterMap;
    mapping (string => uint) public choiceMap;

    constructor(){
        organiser = msg.sender;
        choiceMap["red"] = 0;
        choiceMap["green"] = 0;
        choiceMap["blue"] = 0;
        time = block.timestamp + 7200;
    }

    modifier timeStamp(){
        require(block.timestamp < time,"Election Over");
    _;}

    function vote(string memory _choice) public timeStamp {
        choiceMap[_choice] += 1;
        voterCheck memory _voterCheck = voterCheck(msg.sender,true);
        voterList.push(_voterCheck);
        voterMap[msg.sender] = _voterCheck;
    }

    function winner() public view returns(string memory,uint,uint){
        require(block.timestamp>time);
        string memory _winner;
        _winner = "green";
        if (choiceMap["blue"] > choiceMap[_winner]){
            _winner = "blue";
        }
        if (choiceMap["red"]> choiceMap[_winner]){
            _winner = "red";
        }
        return (_winner,choiceMap[_winner],choiceMap["red"]+choiceMap["green"]+choiceMap["blue"]);
    }
}