// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
  address public manager;
  address payable public winner;
    address payable[] public participants;

    constructor(){
        //give authority to manager
        //creates the manager
        manager = msg.sender;
    }

    //if anyone transact ether he/she will automatically added in participant list
    receive() external payable{
        require(msg.value == 1 ether); 
        participants.push(payable(msg.sender));
    }

    modifier onlyOwner(){
        require(msg.sender == manager, "You should be the owner of the contract");
        _;
    }

    function getBalance() public view onlyOwner returns(uint){
        return address(this).balance;
    }
    function random() public view returns(uint){
        //generates random number
        //you can encode with one string also
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }
    function setWinner() public onlyOwner {
        require(participants.length >= 3, "participant is not greater than 3");
        uint r = random();
        uint index = r % participants.length;
        winner = participants[index];
        winner.transfer(getBalance());
        // reset the participants list
        // now the participants will be zero
        participants = new address payable[](0);
    }

    function allPlayers() public view returns(address payable[] memory){
      return participants;
    }
}
