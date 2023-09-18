pragma solidity ^0.5.0;

import './ERC20Interface.sol';

import './Managed.sol';

contract TokenLottery is Managed {
    address[] private players;
    address[] private lastWinners;
    address public tokenAddress;
    uint public price;
    uint public totalWinners;
    uint public minPlayers;

    event onLotteryEnd(address[]);

    constructor(address _tokenAddress, uint _price, uint _totalWinners, uint _minPlayers) public {
        require(_price > 0 && _totalWinners > 0 && _minPlayers > 0 && _totalWinners < _minPlayers, "Invalid arguments");
        tokenAddress = _tokenAddress;
        price = _price;
        totalWinners = _totalWinners;
        minPlayers = _minPlayers;
    }

    function enter() public {
        require(msg.sender != manager, "Manager not authorized.");

        ERC20Interface tokenContract = ERC20Interface(tokenAddress);

        uint playerBalance = tokenContract.balanceOf(msg.sender);

        require(playerBalance >= price, "Insufficient tokens");

        require(tokenContract.transferFrom(msg.sender, address(this), price), "An error occurred when registering in the lottery.");

        players.push(msg.sender);
    }

    function pickWinners() public onlyManager {
        require(players.length >= minPlayers, "There are not enough participants");

        address[] memory winners = new address[](totalWinners);

        for (uint i = 0; i < totalWinners; i++) {
            winners[i] = pickWinner();
        }

        emit onLotteryEnd(winners);

        lastWinners = winners;

        delete players;

        ERC20Interface tokenContract = ERC20Interface(tokenAddress);

        uint lotteryBalance = tokenContract.balanceOf(address(this));

        require(tokenContract.transfer(manager, lotteryBalance), "An error occurred when closing the lottery.");
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getLastWinners() public view returns (address[] memory) {
        return lastWinners;
    }

    function pickWinner() private returns (address){
        uint index = random() % players.length;

        address winner = players[index];

        removePlayer(index);

        return winner;
    }

    function removePlayer(uint index) private {
        require(index < players.length, "An error occurred when choosing a winner");

        for (uint i = index; i < players.length - 1; i++) {
            players[i] = players[i + 1];
        }

        players.length--;
    }

    function random() private view returns (uint) {
        return uint(keccak256(encodeData()));
    }

    function encodeData() private view returns (bytes memory) {
        return abi.encodePacked(block.difficulty, now, players);
    }

    function () external payable {
        revert("Don't accept ETH");
    }
}