// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Lottery {
  address public immutable OWNER;
  address[] public players;
  uint256 private counter;

  // codigo que define regras imutaveis do contrato
  constructor() {
    OWNER = msg.sender;
  }
  // pede uma quantidade minima para o usuario participar da loteria
  function enter() public payable {
    require(msg.value == 0.1 ether, 'Invalid amout');

    players.push(msg.sender);
  }

  function random() private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      block.timestamp,
      block.difficulty,
      players,
      counter
    )));
  }

  // funcao que pega o ganhador do sorteio e transfere o premio
  function pickWinner() public onlyOwner returns (address payable) {
    address payable winner = payable(players[random() % players.length]);

    winner.transfer(address(this).balance);

    players = new address[](0);

    counter = counter + 1;

    return winner;
  }

  // funcao para mostrar os jogadores
  function getPlayers() public view returns (address[] memory) {
    return players;
  }

  // igual um middleware
  modifier onlyOwner {
    require(OWNER == msg.sender, 'Only Owner');
    // continuar executando o codigo
    _;
  }
}