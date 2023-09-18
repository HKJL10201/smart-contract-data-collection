pragma solidity ^0.4.24;
import './Tournament.sol';
contract Open_Refund is Tournament{


uint p=0;
bytes32 public temp;
uint value=0;

 


 /*Checks if  choice and commit match*/
   function open(uint choices) public payable{
   require(now> current.start_time +current.time_limit && now<=current.start_time+current.open_time+current.time_limit) ;
   require(playersmapped[msg.sender].exist);
   require(playersmapped[msg.sender].choice==0);
   temp = keccak256(abi.encodePacked(choices));
   if( temp == playersmapped[msg.sender].commitment ){
   rightchoice[k++]=msg.sender;
   playersmapped[msg.sender].revealed=true;
   value += playersmapped[msg.sender].choice;
   }
   playersmapped[msg.sender].choice=choices;
   if (msg.sender==rightchoice[k]){
      current.deposit-=(current.refundmoney*(current.number_of_players-1));
      msg.sender.transfer(current.refundmoney*(current.number_of_players-1));
      require(msg.value >= current.lottery_deposit);
      uint a=msg.value;
      uint b=a-(current.lottery_deposit );
      current.tournamentPot+=current.lottery_deposit;
      msg.sender.transfer(b);}
      else
      {
         msg.sender.transfer(msg.value);
      }
   }
   
   
   /*Aim to run a loop and check if any player has not entered the choice. This function should only run after time limit */
   function check_Refund() public{
        require( now>current.start_time+current.open_time+current.time_limit) ;
     ++p;
     require(p==1);
   for(uint counter=0;counter<f;counter++)
   {
       if(playersmapped[addresses[counter]].revealed==false)
       {
           for(uint x=0;x<f;x++)
           {
               if(x!=counter)
               {
                  current.deposit-=current.refundmoney; 
                  uint a=current.refundmoney;
                  addresses[x].transfer(a); 
               }
           }
       }
   }
  }
}
