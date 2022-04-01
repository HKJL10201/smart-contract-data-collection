// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    // declaring the state variables
    address payable[] public players;
    address public manager;

    constructor() {
        // initialize the owner to the address that deploys the contract
        manager = msg.sender;
    }

    // declaring receive() function to receive ETH
    receive() external payable {
        // each player must send exactly 0.1 ETH to participate in the lottery
        require(msg.value == 0.1 ether);
        // adding the player to the players list
        players.push(payable(msg.sender));
    }

    // returns the contract's balance in wei
    function getBalance() public view returns (uint256) {
        // only the manaher is allowed to call it
        require(msg.sender == manager);
        return address(this).balance;
    }

    // helper function that returns a big pseudo random integer
    // do not use in production, consider using Chainlink Verifiable Random Function instead
    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    // selects the winner
    function pickWinner() public {
        // only the manager can pick a winner if there are at least 3 players in the lottery
        require(msg.sender == manager);
        require(players.length >= 3);

        uint256 randomNumber = random();
        address payable winner;

        // computes a random index of the array
        uint256 index = randomNumber % players.length;
        winner = players[index]; // this is the winner

        // transfers the entire contract's balance to the winner
        winner.transfer(getBalance());
        players = new address payable[](0); // resetting the lottery for the next round
    }
}
