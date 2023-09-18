// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.5.0 <0.9.0;

contract Lottery{
    address public manager;
    address payable[] public participants;
    
    //who deployed this smart contract will be the manager
    constructor() {
        manager=msg.sender;
    }
    
    //receives ether from the participants and if particpant send 2 ether then only add them into array
    receive() external payable{
        require(msg.value == 2 ether);
            participants.push(payable(msg.sender));
    }
    
    //gettting the ether balance of this smart contract
    function getBalance() public view returns(uint){
        require(msg.sender==manager);
        return address(this).balance;
    }
    
    //random function for getting the hash not the good way to generete a random hash
    function random() public view returns(uint){
        return uint (keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }
    
    //selecting the winner using the random hash and reseting the contracts
    function selectWinner() public{
        require(msg.sender==manager);
        require(participants.length>=3);
        uint r=random();
        address payable winner;
        uint index = r%participants.length;
        winner=participants[index];
        winner.transfer(getBalance()); //transfer the all contract amount to winner address
        participants=new address payable[](0); //reset the participants array
    }
}