pragma solidity ^0.5.4;

import "./Owned.sol";

contract Lottery is Owned {

    address[] public players;

    function participate() public payable {
        require(msg.value >= .01 ether);
        players.push(msg.sender);
    }

    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public onlyOwner {
        require(players.length > 0);

        // uint index = random() % players.length;
        // players[index].transfer(address(this).balance);

        players = new address[](0); // Reset
    }

    function getPlayers() public view returns(address[] memory) {
        return players;
    }
}
