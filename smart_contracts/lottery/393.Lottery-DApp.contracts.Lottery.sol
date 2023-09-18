// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract Lottery {
    
    // declare all important variables
    address private owner;
    address[] public playerList;
    bool isLotteryOpen;
    address payable public winner;
    uint public num_players;
    
    constructor() {
        owner = msg.sender;
        num_players = 0;
        isLotteryOpen = false;
        winner = address(0);
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Only the Owner can perform this action");
        _;
    }
    
    modifier notOwner() {
        require(msg.sender != owner, "Owner cannot perform this action");
        _;
    }
    
    // owner must open lottery to collect ether
    function openLottery() public isOwner {
        isLotteryOpen = true;
    }
    
    // owner must close lottery to select winner 
    function closeLottery() public isOwner {
        isLotteryOpen = false;
    }
    
    // check if address already entered lottery
    function inLottery(address player) private view returns (bool) {
        
        for(uint i = 0; i < uint(playerList.length); i++) {
            if (playerList[i] == player) {
                return true;
            }
        }
        return false;
    }
    
    // any address can join lottery once for 1 ether 
    function joinLottery() payable public notOwner {
        require(isLotteryOpen, "Lottery is not open yet. Check back later.");
        require(!inLottery(msg.sender), "You can only join the lottery once.");
        require(msg.value == 1 ether, "Costs 1 ether to play.");
        require(winner == address(0), "There is already a winner to this lottery.");
        
        playerList.push(msg.sender);
        
        num_players++; 
    }
    
    // randomly select winner 
    function generateWinner() public isOwner {
        
        require(!isLotteryOpen, "Lottery must be closed to declare a winner.");
        require(winner == address(0), "There is already a winner to this lottery.");
        require(num_players > 0, "There are no entries in the lottery.");
        
         
        uint index = generateRandomNumber();
        
        winner = payable(playerList[index]);
        
        winner.transfer(num_players * 1 ether);
        
        emit WinnerDeclared(winner, num_players);
        
    }
    
    // my solution generating a random number 
    function generateRandomNumber() private view returns (uint) {
        return uint(uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty))) % num_players);
    }
    
    // reset lottery settings
    function resetLottery() public isOwner {
        playerList = new address[](0);
        isLotteryOpen = true;
        num_players = 0;
        winner = address(0);
    }
    
    event WinnerDeclared( address winner, uint num_players );
}