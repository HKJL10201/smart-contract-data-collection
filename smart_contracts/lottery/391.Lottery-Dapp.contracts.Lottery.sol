// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address payable[] public players;
    address payable public winner;
    address payable public manager;
    uint256 public totalFunds;
    bool public isLotteryOpen;

    constructor() {
        manager = payable(msg.sender);
        isLotteryOpen = true;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "You do not have access to this function");
        _;
    }

    function participate() external payable {
        require(isLotteryOpen, "Lottery is closed");
        require(msg.value == 1 ether, "Pay 1 ETH to participate");

        players.push(payable(msg.sender));
        totalFunds += msg.value;
    }

    function pickWinner() public onlyManager {
        require(isLotteryOpen, "Lottery is closed");
        require(players.length >= 3, "Insufficient number of players");

        uint256 index = _generateRandomNumber() % players.length;
        winner = players[index];

        uint256 winnerShare = (totalFunds * 8) / 10;
        winner.transfer(winnerShare);
        manager.transfer(address(this).balance);

        players = new address payable[](0);
        totalFunds = 0;
        isLotteryOpen = false;
    }

    function _generateRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function getBalance() public onlyManager view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getManager() public view returns (address) {
        return manager;
    }

    function getWinner() public view returns (address payable) {
        return winner;
    }

    function endLottery() public onlyManager {
        require(isLotteryOpen, "Lottery is already closed");
        selfdestruct(manager);
    }

    function reopenLottery() public onlyManager {
        require(!isLotteryOpen, "Lottery is already open");
        isLotteryOpen = true;
    }
}
