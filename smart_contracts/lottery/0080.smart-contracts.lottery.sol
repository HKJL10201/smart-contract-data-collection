//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract lottery{
    
    address public manager;
    address payable[] public participants ;
 

    constructor() {
        manager=msg.sender;
     
    }
    receive() external payable{
    require(msg.value>=1 ether,"lottery ticket costs 1 ether");
    participants.push(payable(msg.sender));
      
    }
    function getBalance() public view returns(uint){
        require(msg.sender==manager,"you can not check balance");
        return address(this).balance;
        }
    
        function random() public view returns(uint){
    return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,participants.length)));  //gives a long hash value
}
    function winnerSelection() public{
           require(msg.sender==manager,"you cannot access it");
           require(participants.length>=3,"there should be atleast 3 participants");
           uint r=random();
           address payable winner;
           uint index=r % participants.length;   //to convert long hash value into single value and that should be less than participants.length
           winner=participants[index];
           winner.transfer(getBalance());
           //return winner;
           participants=new address payable[](0);   //to reset after lottery is completed
    }    


}