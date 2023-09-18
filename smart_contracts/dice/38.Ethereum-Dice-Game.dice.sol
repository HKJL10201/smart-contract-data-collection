pragma solidity ^0.4.17;

contract diceGame {
    // Address of Creator & Players (Tracks Duplicates), The Sum of two 6 Sided Die
    address public creator;
    address[4] public played;
    uint public num_played = 0;
    uint256 public dice_sum = uint(block.blockhash(block.number-1))%6 + 1 + uint(block.blockhash(block.number-1))%6 + 1;
    
    //List of Events that track status of the Game and put them on the blockchain
    event Played (address player);
    event Won (address player);
    event Lost(address player);
    
    // Sets Creator as the House
    function diceGame () public {
        creator = msg.sender;
        add_player (msg.sender);
    }
    // Adds Players while checking for Duplicates 
    function add_player (address player) private {
    for (uint i = 0; i < num_played; i++) {
      require (player != played[i]);
    }
    assert (played[num_played] == 0);
    played[num_played] = player;
    num_played = num_played + 1;
    Played (player);
    if (num_played == played.length) {
       dicePlay();
    }
  }
   // Betting Function (max bet = .1 eth) 
    function play () external payable {
     require (msg.value == 100 finney);
     require (num_played < played.length);
     add_player (msg.sender);
  }
  
  // Determines Winner by Rolling Two Die, Odd Sum = Win / Even Sum = Lost ; Winner recieves double the bet
    function dicePlay() public payable returns (bool result) {
        if(dice_sum % 2 == 1){
            Won(msg.sender);
            msg.sender.transfer(this.balance * 2);
            result = true;
        }else {
        Lost(msg.sender);
        result = false;
        }
    }
}
