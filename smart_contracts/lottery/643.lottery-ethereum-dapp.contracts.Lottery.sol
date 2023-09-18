pragma solidity ^0.5.7;

contract  Lottery {
    address public manager;
    address payable[] public players;

    constructor() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether); //if returns true code continues
        players.push(msg.sender);
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance); //method on type address
        players = new address payable[](0); //initial size of 0 elements
    }

    function random() private view returns (uint) {
      return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
