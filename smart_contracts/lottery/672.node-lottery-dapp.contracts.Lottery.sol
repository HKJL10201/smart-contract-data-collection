pragma solidity ^0.4.22;

import "./Owned.sol";

contract Lottery is Owned {

    address[] public players;
    mapping(uint => uint) commonRandom;

    function participate() public payable {
        require(msg.value >= .01 ether);
        players.push(msg.sender);
    }

    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public onlyOwner {
        require(players.length > 0);

        uint index = random() % players.length;
        players[index].transfer(address(this).balance);

        players = new address[](0);
    }

    function getPlayers() public view returns(address[]) {
        return players;
    }
}
