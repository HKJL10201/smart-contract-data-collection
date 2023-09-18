pragma solidity ^0.4.17;

contract Lottery {
  address public manager;
  address[] public players;

  function Lottery() public {
    manager = msg.sender;
  }

  function enter() public payable {
    //Validation - value in WEI converted to ETH
    require(msg.value > .01 ether);

    players.push(msg.sender);
  }

  function random() private view returns (uint256) {
    return uint256(keccak256(block.difficulty, now, players));
  }

  function pickWinner() public restricted {
    //using restricted modifier -> same as remove all function code and add to _; modifier
    uint256 index = random() % players.length;
    players[index].transfer(this.balance); //instance of a contract
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
