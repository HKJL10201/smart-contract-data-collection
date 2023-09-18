pragma solidity  ^0.4.17;

contract Lottery {

    //Creating the manager variable
     address public manager;
     //Creting the dynamic array which will contain the players addresses
     address[] public players;

  //Contract constructor
  function Lottery() public{
      //Setting the creator of the contract to be the manager of the Lottery
      manager = msg.sender;
  }

  //Function used to enter in the Lottery
  function enter() public payable {
      //Requiring the person who wants to enter the Lottery to submit at least .01 ether
      require(msg.value > .01 ether);

      //If the require is fullfilled, add the player to the players array
      players.push(msg.sender);
  }

  //Function for setting a "random number" to pick the winner
  function random() private view returns (uint) {
     return uint(keccak256(block.difficulty, now, players));
  }

  //Function for picking the winner of the Lottery, only the manager can call this function
  function pickWinner() public restricted {

      //Getting a random index to select a winner
      uint index = random() % players.length;

      //Transfer the winner all the ether from this contract
      players[index].transfer(this.balance);

      //Reset the address array of participants
      players = new address[](0);
  }

  //Used to set functions restricted only to managers
  modifier restricted() {
      require(msg.sender == manager);
      _;
  }

  //Function to get all the players
  function getPlayers() public view returns (address[]) {

      //Return all the players
      return players;

  }

}
