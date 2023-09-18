pragma solidity ^0.4.24;

contract Tournament {

   struct tournament{
   uint time_limit;
   uint number_of_players;
   uint lottery_deposit;
   uint tournamentPot;
   uint start_time;
   uint deposit;
   uint open_time;
   uint refundmoney;
   } tournament public current;
   
   
   
   struct Player {
		address account;                                    //address of that player
		bytes32 commitment;                            //hash of 256 bytes its hash of choice 
		uint choice; 
		bool revealed;
		bool exist;//This is its choice ..we take its hash and store in commitment  
	} 
	
	
	mapping (address => Player) public playersmapped; 
    mapping (uint =>address) internal rightchoice;
	mapping(bytes32=>address) internal commit_to_address;
	mapping(uint=>address) internal  addresses;
	uint k=0;uint t=0;uint f=0;

   /*Initializing the tournament players and time limit*/
   function setup(uint _time,uint _number_of_players,uint Lottery_deposit,uint _opentime,uint refund) public{
        t++;
        require(t==1);
       if(refund<=Lottery_deposit){revert("Please enter inputs correctly");}
       current = tournament(_time,_number_of_players,Lottery_deposit*1 ether,0,now,0,_opentime,refund*1 ether);
   }
   
   function getcommit(uint _choice) pure public returns(bytes32)
   {
       return(keccak256(abi.encodePacked(_choice)));
   }
   
	
   /*places the player inside the array of structss*/	
    function Register(bytes32 commit) payable public{
   require(now< current.start_time +current.time_limit && now>=current.start_time) ;
   require(f<current.number_of_players);
   if(playersmapped[msg.sender].exist){revert("You already registered");}
   if(commit_to_address[commit]!=address(0)){revert("Enter a different commit");}
  require (msg.value >= (current.number_of_players-1)*current.refundmoney);                                         //add a player only if it has more than 1000 ether
   playersmapped[msg.sender] =	Player(msg.sender,commit,0,false,true);	
   commit_to_address[commit]=msg.sender;
   addresses[f]=msg.sender;
   f++;
   uint a=msg.value;
   uint b=a-((current.number_of_players-1)*current.refundmoney );
   current.deposit+=(current.number_of_players-1)*current.refundmoney;
   msg.sender.transfer(b );
 }
 }  
