 // SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract LotterContact{

    address public manager;
    address payable[]  public participants;
    constructor(){
        manager=msg.sender;
    }
    //This receive function is used to receive the participation fee from the participant
    receive() external payable {
        require(msg.value==1 ether);
        participants.push(payable(msg.sender));
    }

    // This function returns the total balance of the lottery that  the winner can get
    function getBalance() public view returns(uint){
        require(msg.sender==manager);
        return address(this).balance;
    }
    
   //This method select the random participant address and send all the balance available  for manager 
    function selectWinnerAndSendWinningAmount() public  {
        require(msg.sender==manager);
        require(participants.length>2);
        uint winnerhash= uint(keccak256(abi.encodePacked("Lotter",address(this), block.timestamp)));
        uint winnerindex=winnerhash % participants.length;
       address payable finalwinner ;
       finalwinner= participants[winnerindex];
       finalwinner.transfer(getBalance());       
        participants= new address payable[](0);
   

    }
   
}
