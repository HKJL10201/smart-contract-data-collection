// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    //declaring a manager variable of address type
    address public manager;
    //declaring a participants array of address type which is payable i.e. can recieve ethers
    address payable[] public participants;

    constructor(){
        //according to our structure of code manager is going to be the owner of this contract that's why
        //using msg.sender(a global variable) here
        manager=msg.sender;
    }

    //using receive function so that we can transfer some amount of ethers in our contract this must 
    //be external always, this function can be used only once.
    receive() external payable{
        //require works similar to if-else, in this case if the ethers sended by the user is equal to
        // 2 ethers then only the next line will get excuted.
        require(msg.value==2 ether);
        //pushing the address of the participants(using msg.sender) in the partcipants array 
        participants.push(payable(msg.sender));
    }
    
    //funcctions which returns the amount of ether being sended over to our contract
    function getBalance() public view returns(uint){
        //if the address is equal to that of manager then only show the balance
        require(msg.sender== manager);
        return address(this).balance;
    }
    // function to generate random winner using keccak256 it will return 64hex decimal value
    function random() public view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }
    //this function will select the winner and will pay the winner amount to randomly selected participant
    function selectWinner() public
     {
        require(msg.sender==manager);
        require(participants.length>=3);
        // require(getBalance()>=6 ether);
        uint r=random();
        address payable winner;
        uint index = r % participants.length;
        winner=participants[index];
        winner.transfer(getBalance());
        //after successful transfer of ethers to winner participants array become null
        participants=new address payable[](0);
    }

}
