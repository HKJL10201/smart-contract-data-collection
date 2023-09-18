pragma solidity ^0.5.8;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value >= 0.01 ether, "not enough funds");
        players.push(msg.sender);
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encode(players)));
    }

    function pickWinner() public restricted() {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }

    modifier restricted() {
        require(manager == msg.sender, "Function restricted to owner.");
        _;
    }
}