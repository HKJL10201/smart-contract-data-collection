pragma solidity ^0.5.0;

contract Lottery {
    address public owner;
    address payable[] public players;

    constructor() public {
        owner = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .001 ether);
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    function pickWinner() public onlyOwner {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}