// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery{

    address public manager;
    //global dynamic array for participants.
    address payable[] public participants;

    constructor()
    {
        //msg.sender is a global variable used to store contract address to manager.
        manager=msg.sender; 
    }

  //receive function only creates once in a smart comtract. 
  //this function help to transfer the ether.
  //always use with external keyword and payable.
     receive() external payable{
         //require is used as a if statement. it check if ether value is 2 then only run below code.
         require(msg.value==0.02 ether);
         participants.push(payable(msg.sender));
     }

    function getBalance() public view returns(uint){
        //only manager check the total balance.
        require(msg.sender==manager);
        return address(this).balance;
    }
    
    //this random function will genrate random value and from participant array and then return to the winnerFunction.
    function random() public view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

//this function decide the winner randomly.
    function selectWinner() public{
        require(msg.sender==manager);
        require(participants.length>=3);
        uint r=random();  //call random function.
        uint index=r % participants.length;   //for making random function value in array length range.
        address payable winner;
        winner=participants[index];
        winner.transfer(getBalance());
        participants=new address payable[](0);

    }



    
}
