//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract Lottery {
    address payable[] public players;
    address public manager;
    address payable public winner;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value == 0.01 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint) {
        require(msg.sender == manager,"You are not the manager");
        return address(this).balance;
    }

    function random() internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function pickWinner() public {
        require(msg.sender == manager,"You are not the manager");
        require(players.length >= 3,"Players are less than 3");
        uint256 r = random();
        uint256 index = r % players.length;
        // setting the winner
        winner = players[index];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }

    // since its array we have to use memory
    function allPlayers() public view returns (address payable[] memory) {
        return players;
    }
}

// 0x4c13Ad251A183db441d91EE5BEBF0cBAf050483d
