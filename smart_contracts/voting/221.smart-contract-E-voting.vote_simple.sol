pragma solidity ^0.8.1;

contract Election
 {
     uint public vote_p_1 = 0;
     uint public vote_p_2 = 0;
     
     mapping (address => uint) public voters;
     
     function vote(uint choix) public
     {
         require (voters[msg.sender]!=1, "Tu ne peux plus voter!");
         if (choix == 1) vote_p_1 = vote_p_1+1;
         else vote_p_2=vote_p_2+1;
         voters[msg.sender] = 1;
         
     }
 }
