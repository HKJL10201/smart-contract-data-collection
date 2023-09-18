// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

contract Lottery {
    struct Winner {
        address player;
        uint position;
        uint256 amount;
        uint256 serial;
    }

    Winner[] public winners;
    address payable[] public players;
    address payable public admin;
    uint256 serial;

    constructor() {
        // Initialize the admin address to the creator of the contract.
        admin = payable(msg.sender);
        serial = 1;
    }

    receive() external payable {
        uint256 eth = msg.value;
        require(eth >= 1 ether, "Please send some ether");

        // Add the sender to the list of players.
        players.push(payable(msg.sender));
    }

    function totalPlayer() public view returns (uint256) {
        return players.length;
    }

    function balance() public view returns (uint256) {
        require(msg.sender == admin, "Are you admin?");
        return address(this).balance;
    }

    function play() payable public {
        require(msg.sender == admin, "Only admin can start a spin.");

        uint256 numberOfPlayers = players.length;
        require(numberOfPlayers >= 10, "Few more tickets to be sold");

        selectWinner(1);
        selectWinner(2);
        selectWinner(3);

        players = new address payable[](0);

        // Transfer profit to admin
        // admin.transfer(address(this).balance);
        serial++;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    function selectWinner(uint256 position) private  {
        uint256 winnerAt = random() % (11 - position);
        address payable winner = players[winnerAt];
        uint256 amount = (5-1) * 1 ether;
        winner.transfer(amount);
        winners.push(Winner(winner, position, amount, serial));
        delete players[winnerAt];
    }
}
