pragma solidity ^0.4.20;

contract Casino {
   address public owner;
   uint256 public minimumBet;
   uint256 public totalBet;
   uint256 public numberOfBets;
   uint256 public maxAmountOfBets = 5;
   address[] public players;

   struct Player {
      uint256 amountBet;
      uint256 numberSelected;
   }
   // The address of the player => user info
   mapping(address => Player) public playerInfo;
   function() public payable {} //Fallback function in case someone sends eth to this contract


   function Casino(uint256 _minimumBet) public {
      owner = msg.sender;
      if(_minimumBet != 0) minimumBet = _minimumBet;
   }

   function kill() public {
      if(msg.sender == owner) selfdestruct(owner);
   }

   // Bet for a number between 1 and 10 both inclusive
   function bet(uint256 numberSelected) public payable {
      require(!checkPlayerExists(msg.sender));
      require(numberSelected >= 1 && numberSelected <= 10);
      require(msg.value >= minimumBet);
      playerInfo[msg.sender].amountBet = msg.value;
      playerInfo[msg.sender].numberSelected = numberSelected;
      numberOfBets++;
      players.push(msg.sender);
      totalBet += msg.value;

      if(numberOfBets >= maxAmountOfBets) {
          uint256 randomNumber = generateNumberWinner();
          distributePrizes(randomNumber);
      }
   }

   function checkPlayerExists(address player) public constant returns(bool){
      for(uint256 i = 0; i < players.length; i++){
          if(players[i] == player) return true;
      }
      return false;
   }

   // Modifier to only allow the execution of functions when the bets are completed
   modifier onEndGame(){
      if(numberOfBets >= maxAmountOfBets) _;
   }

   // Generates a number between 1 and 10 that will be the winner
   function generateNumberWinner() public constant returns(uint256) { //TODO add onEndGame here
      uint256 numberGenerated = block.number % 10 + 1; // TODO change to be truly random
      return numberGenerated;
   }


   // Sends the corresponding ether to each winner depending on the total bets
   function distributePrizes(uint256 winningNumber) onEndGame {
      address[5] memory winners;
      uint256 count = 0; // This is the count for the array of winners
      for(uint256 i = 0; i < players.length; i++){
         address playerAddress = players[i];
         if(playerInfo[playerAddress].numberSelected == winningNumber){
            winners[count] = playerAddress;
            count++;
         }
         delete playerInfo[playerAddress]; // Delete all the players
      }
      assert(winners.length > 0); //TODO double check so you don't do divide by 0
      uint256 winnerEtherAmount = totalBet / winners.length; // How much each winner gets

      for(uint256 j = 0; j < count; j++){
         if(winners[j] != address(0)) // Check that the address in this fixed array is not empty
         winners[j].transfer(winnerEtherAmount);
      }

      players.length = 0; // Delete all the players array
      totalBet = 0;
      numberOfBets = 0;
   }
}
