pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
      // set manager based on who created the contract
      manager = msg.sender;
    }
    function enter() public payable {
      // user must enter w/ at least 0.01 ether
      require(msg.value > .01 ether);
      players.push(msg.sender);
    }

    function random() private view returns (uint) {
      return uint(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public restricted {
      // choose random index from players array
      uint index = random() % players.length;
      // transfer balance of contract to winner
      players[index].transfer(this.balance);
      // initialize a new players array
      players = new address[](0);
    }

    modifier restricted() {
      require(msg.sender == manager);
      _;
    }

    function getPlayers() public view returns (address[]) {
      return players;
    }
}
