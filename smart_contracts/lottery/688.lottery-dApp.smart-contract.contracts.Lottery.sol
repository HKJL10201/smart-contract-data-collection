// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Lottery {
    address owner;
    address payable[] players;
    uint public lotteryId;
    mapping(uint => address payable) public lotteryHistory;

    event NewPlayer(address indexed from, uint amount);

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }

    function enterLottery() public payable {
        require(msg.value >= 0.1 ether, "Not enough ether sent");
        players.push(payable(msg.sender));

        if(address(this).balance >= 0.5 ether) {
            pickWinner();
        }

        emit NewPlayer(msg.sender, msg.value);
    }

    function pickWinner() private {
        uint randomNumber = getRandomNumber() % players.length;
        players[randomNumber].transfer(address(this).balance);

        lotteryHistory[lotteryId] = players[randomNumber];
        lotteryId++;
   
        players = new address payable[](0);
    }

    function getRandomNumber() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function getPlayerList() public view returns(address  payable[] memory) {
        return players;
    }

    function getBalance () public view returns(uint) {
        return address(this).balance;
    }

    function getWinnerByLotteryId (uint id) public view returns (address payable) {
        return lotteryHistory[id];
    }
}