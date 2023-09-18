pragma solidity ^0.4.24;

import './Open_Refund.sol';


contract Compute_winner is Open_Refund{

address winner;

	function compute_winner() public payable  {
	    
	  require( now>current.start_time+current.open_time+current.time_limit) ;
	 uint m=value%k;
	 winner=rightchoice[m];
	 uint a=current.tournamentPot;
	 current.tournamentPot=0;
	 winner.transfer(a);
		      
}	
  function getwinner() public view returns(address){
        return winner;
    }
    
}
	

