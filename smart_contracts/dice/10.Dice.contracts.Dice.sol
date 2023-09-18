// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.25 <0.7.0;

/** 
 * @title Dice
 * @dev Implements logic of 12-sided dice
 */
contract Dice {
   mapping(address => uint) public score;
   uint randNonce = 0; 
   
   function roll() public {
    randNonce++;
    score[msg.sender] = uint(keccak256(abi.encodePacked(block.timestamp,  
                                          msg.sender,  
                                          randNonce)))%12;
   }
   
   function getMyScore() public view returns(uint){
       return(score[msg.sender]);
   }


}
