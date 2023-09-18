//SPDX-License-Identifier: MIT
//There is a problem while calling blockhash on Javascript VM. As an environment, please select Custom-External Http Provider, Ganache.

pragma solidity ^0.8.19;

contract Lottery{
    uint public lottery_over_block;

    //list of the players - payable modifier in order to receive payment or ether
    address payable[] public players;
    int private winner_index = -1;
    address payable private winnerAddress;

    constructor() {
        //block number determining the end of the lottery
        lottery_over_block = block.number + 5;
    }

    function joinTheLottery() public payable {
        require(block.number < 1+lottery_over_block, "The lottery has ended!");
        //player should send some ether to join requirement
        require(msg.value > .01 ether, "Minimum bet is 0.01 ether!");
        // Maximum 5 players
        require(players.length < 5, "Maximum 5 players per lottery!");
        // Only one ticket per account.
        require(!hasUserJoined(msg.sender), "User has already joined the lottery!");

        //add the address who invokes this function to the players array
        players.push(payable(msg.sender));
    }

    function hasUserJoined(address user) private view returns (bool) {
        for (uint i = 0; i < players.length; i++) {
            if (players[i] == user) {
                return true;
            }
        }
        return false;
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

    function getLotteryEndBlock() public view returns (uint) {
        return lottery_over_block;
    }

    function hasLotteryEnded() public view returns (bool) {
        bool lotteryEnded =  block.number >= lottery_over_block || players.length == 5;
        return lotteryEnded;
    }


    function collectPrize() public {
        require(winner_index != -1, "Winner has not been decided yet!");
        require(msg.sender == players[uint(winner_index)],"Only the winner can collect the prize!");
        //transfer the balance of the smart contract to the winner
        players[uint(winner_index)].transfer(address(this).balance);
        // Reset the lottery
        delete players;
        //Reset the lottery
        // Set lottery_over_block to 5 blocks after the current block
        lottery_over_block = block.number + 5;
        winner_index=-1;
    }

    function resetLottery() public {
        require(players.length == 0, "Can only reset empty lottery!");
        lottery_over_block = block.number + 5;
    }

    function winner() public {
        require(block.number >= lottery_over_block, "The lottery has not ended yet!");
        require(winner_index == -1, "Winner has already been decided!");
        require(players.length > 0, "No players in the lottery!");

        //The hash of the block where the lottery ends, the timestamp of the previous block and the PREVRANDAO Opcode of the previous block decide the winner.
        // Using the timestamp and prevrandao of the block where the lottery ends would be safer, but it is not supported by Solidity.
        uint index = uint(keccak256(abi.encodePacked(blockhash(lottery_over_block), block.timestamp, block.prevrandao)));
        winner_index = int(index % players.length);
        winnerAddress = players[uint(winner_index)];
    }

    function getWinnerAddress() public view returns (address) {
        //display the winneraddress of the finished round
        require(winnerAddress!=address(0),"No winner yet");
        return winnerAddress;
    }

    function getBalance() public view returns (uint) {
        //view but not modify the lottery balance
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory){
        //stored temporarily only in the func lifecycle
        return players;
    }

}