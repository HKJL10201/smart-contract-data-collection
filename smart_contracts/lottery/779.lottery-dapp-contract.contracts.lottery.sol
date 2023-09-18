pragma solidity ^0.4.17;

contract Lottery {
    address public manager;

    function Lottery () public {
        manager = msg.sender;
    }
 
   address[] public players;

   function enter() public payable {
       require(msg.value > 0.0001 ether);
       players.push(msg.sender);
   }

   function random() private view returns (uint) {
       return uint(sha256(block.difficulty,now,players));
   }

   function pickWinner() restricted public {
       uint index = random()%players.length;
       players[index].transfer(this.balance);
       players = new address[](0);
   }

   modifier restricted {
       require(msg.sender == manager);
        _;
   }

    function getPlayers() view public returns (address[]) {
        return players;
    }

}