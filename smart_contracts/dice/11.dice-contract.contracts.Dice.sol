pragma solidity ^0.4.24;

/*import "./Signidice.sol";*/
/*import "./openzeppelin/math/SafeMath.sol";*/

contract Dice {

 /* using SafeMath for uint256; */

 address public casino;
 address public player;
 uint public point = 0;
 bool public gameOver = false;
 bool public gameInPlay = false;
 uint public stake;
 string public outCome = "";
 uint8 public role;

 event WinEvent(string);
 event LooseEvent(string);

 constructor() public {
   casino = msg.sender;
 }

 modifier checkGameIsOver() {
   require(!gameOver, "The game is over.");
   _;
 }

 modifier checkGameInPlaying() {
   require(!gameInPlay, "The game is not over yet.");
   _;
 }

 modifier checkPlayer() {
   require(player == msg.sender, "You are not the user that started this game");
   _;
 }

 function newGame() public payable checkGameInPlaying {
   require(msg.value >= 1, "You must bet a minimum of 1 ETH");
   player = msg.sender;
   stake = msg.value;
   point = 0;
   role = 0;
   gameOver = false;
   gameInPlay = true;
   outCome = "";

   roleDice();
 }

 function roleDice() public checkGameIsOver checkPlayer {
   role = random();

   if ( (role == 7 || role == 11) && point == 0 ) {
     lose();
     return;
   }

   if ( role == 7 && point != 0 ) {
     lose();
     return;
   }

   if ( ( role == 2 || role == 3 || role == 12 ) && point == 0 ) {
     win();
     return;
   }

   if ( point != 0 && role == point ) {
     win();
     return;
   }

   if ( point == 0 ) {
       point = role;
       return;
   }
 }

 function lose() private {
   gameOver = true;
   /* take stake and send it to casino address */
   address(casino).transfer(stake);
   gameOver = true;
   gameInPlay = false;
   emit LooseEvent("Player lost");
   outCome = "Lose";
 }

 function win() private {
   gameOver = true;
   /* Send stake plus winnings to player */
   gameOver = true;
   gameInPlay = false;
   uint  winings = stake * 12;
   address(player).transfer(winings);
   emit WinEvent("Player won");
   outCome = "Win";
 }

 function random() private view returns (uint8) {
   return uint8(uint256(keccak256(block.timestamp, block.difficulty))%12);
 }
}
