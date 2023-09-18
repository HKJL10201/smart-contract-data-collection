//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lottery {
    address payable[] public players;
    address public manager;

    constructor(address eoa) {
        manager = eoa;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    receive() external payable {
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view onlyManager returns (uint256) {
        return address(this).balance;
    }

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

    error lotteryError(string _error);

    function pickWinner() public onlyManager {
        if (players.length < 3) {
            revert lotteryError("Not enough players");
        }
        uint256 winner = random() % players.length;
        players[winner].transfer(getBalance());

        players = new address payable[](0);
    }
}


// A simple lottery contract that creates a new lottery contract
contract LotteryCreator {
    Lottery[] public lotteries;

    function createLottery() public payable {
        Lottery lottery = new Lottery(msg.sender);
        lotteries.push(lottery);
    }
}
