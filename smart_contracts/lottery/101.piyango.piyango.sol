// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Piyango{
    address public owner;
    address payable[] public participants;
    uint public piyangoCount; //security for reentry
    mapping (uint => address payable) public piyangoHistory;

    constructor(){
        owner = msg.sender;
        piyangoCount = 1; //security for reentry
    }

    function getWinnerByPiyango(uint piyangoId) public view returns(address payable){
        return piyangoHistory[piyangoId];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getParticipants() public view returns(address payable[] memory) {
        return participants;
    }

    function enterPiyango() public payable {
        require(msg.value > 0.01 ether);
        
        participants.push(payable(msg.sender)); //address of player entering piyango
    }

    function randomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function pickWinner() public onlyowner {
        uint index = randomNumber() % participants.length;
        
        //transfer the funds the address randomly selected
        participants[index].transfer(address(this).balance);

        piyangoHistory[piyangoCount] = participants[index];
        piyangoCount++;
        

        // reset the state of the contract
        participants = new address payable[](0);
    }

    modifier onlyowner() {
      require(msg.sender == owner);
      _;
    }
}


