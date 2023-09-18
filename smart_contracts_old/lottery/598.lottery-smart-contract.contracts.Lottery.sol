// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Lottery {
    address payable public manager;
    address payable[] public players;
    mapping(address => uint256) public balances;
    uint256 public accumulatedPrize;

    constructor() {
        manager = payable(msg.sender);
    }

    function enter() public payable {
        // validate the payable
        require(msg.value >= 1 ether);

        players.push(payable(msg.sender));
        accumulatedPrize += msg.value;
    }

    function pickWinner() public restricted {
        // Choose the winner
        address winner = players[generateUnsafeRandomNumber() % players.length];

        uint256 prize = (accumulatedPrize / 100) * 98;
        uint256 fee = accumulatedPrize - prize;

        // Send the prize to winner
        balances[winner] += prize;

        // Send fee to manager
        balances[manager] += fee;

        // Reset
        players = new address payable[](0);
        accumulatedPrize = 0;
    }

    function withdraw() public {
        address payable player = payable(msg.sender);

        uint256 prize = balances[player];
        require(prize > 0, "No prize for this player.");

        bool success = player.send(prize);
        require(success, "Error on sending the prize.");

        delete balances[player];
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function generateUnsafeRandomNumber() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}
