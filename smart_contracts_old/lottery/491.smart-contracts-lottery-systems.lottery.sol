pragma  solidity ^0.4.17; 
contract  Lottery {
    
    // variable declerations
    address public owner;
    uint public hash_int;
    
    
    
   //map declerations for count of token/balance
    address[] public players;
      mapping(address => uint) public token;
      
      
      
      
      //Lottery constructor
    function Lottery() public {
        
        owner=msg.sender;
       hash_int= uint24(keccak256(block.difficulty,now,players));
            //for making hash value less than or equal to 1000000 as uint24 can have greater value (remove this if gas is exhausted)
       while(hash_int > 1000000){
       if(hash_int > 1000000){
       hash_int=hash_int-1000000;
       }
      
    }
    }

    //participate fuction
    function participate() public payable{
        //decleration of eth_wei(1 eth equals how many wei)
        uint eth_wei=1000000000000000000;
        
        //checking the condition of minmal token
        require(msg.value > 1 ether);
        
        
        //send variable for sending decimal values(here send is of uint type as we are dealing in wei )
        uint send=msg.value-(msg.value/eth_wei)*eth_wei;
        
        //transfering decimal values
        msg.sender.transfer(send);
        
        //calculating integer value which is to be added to uses token
        uint count = uint((msg.value/eth_wei)*eth_wei);
        
        
        //adding token
        token[msg.sender]=count;
        
        //pushing hash of players in array
        players.push(msg.sender);
    }
    
    
    //make guess function
    function makeGuess(uint guess) public{
        //requirement of guess to be greater than 1 and less than 1000000
        require(guess >1);
        require(guess < 1000000);
        
        //requirement of token to be geater than 1 as each time 1 ether is deducted
        require(token[msg.sender] >= 1);
        token[msg.sender]=token[msg.sender]-(1 ether);
        
    
        
        
    }

    
    //close game function
    function closeGame() public{
        //can only be called by owner
        require(msg.sender == owner);
      
      //calculating index of winner
        uint index = hash_int % players.length;
        
        //transferring half amount to winner
        uint bal=address(this).balance/2;
        players[index].transfer(bal);
        //transferring half amount to owner
        owner.transfer(bal);
        
        //reinitiallising addresses to zero to end game(removing address)
        players = new address[](0);
    
    }
}
