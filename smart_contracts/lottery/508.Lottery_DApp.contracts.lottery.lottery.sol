// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./SafeMath.sol";

import "./IERC20.sol";

contract Lottery {
    using SafeMath for uint256;
    
    address public manager;
    mapping(address => uint256) public winners;
    address[] public players;
    address[] private lotteryList;
    uint256 public startTime;
    address public firstWinner;
    address public secondWinner;

    //total lotteryTokens in lottery
    uint256 public lotteryTokens;

    //constants for lottery
    address private _tokenAddress;
    uint256 private _ticketValue;

    event changeTotalTokens(uint);
    event lotteryEnded(address, address, uint);
    event ticketValueChanged(uint);
    event transferBonus(address, uint);
    
    modifier isNotManager() {
        require(msg.sender != manager);
        _;
    }
    
    modifier isManager() {
        require(msg.sender == manager);
        _;
    }
    
    modifier isNotInList() {
        for (uint i=0; i < players.length; i++) {
            require(msg.sender != players[i]);
        }
        _;
    }

    modifier isWinner() {
        require(winners[msg.sender] > 0);
        _;
    }
    
    modifier isAnyPlayers() {
        require(players.length > 0);
        _;
    }

    modifier isPeriod() {
        require(now >= startTime.add(604800));
        _;
    }
    
    constructor(address tokenAddress, uint ticketValue) public {
        _tokenAddress = tokenAddress;
        _ticketValue = ticketValue;
        manager = msg.sender;
        startTime = now;
    }

    function isInLottery() public view isNotManager returns(bool) {
        for(uint i = 0; i < players.length; i++) {
            if(players[i] == msg.sender) return true;
        }
        return false;
    }

    function tokenAddress() public view isManager returns (address) {
        return _tokenAddress;
    }

    function getWinners() public view returns(address, address) {
        
        return (firstWinner, secondWinner);
    }

    function getStartTime() public view returns(uint) {
        return startTime;
    }

    function ticketValue() public view returns (uint) {
        return _ticketValue;
    }

    function changeToken(address token) public isManager returns (bool) {
        _tokenAddress = token;
        return true;
    }

    function changeTicketValue(uint ticket) public isManager returns (bool) {
        _ticketValue = ticket;
        emit ticketValueChanged(_ticketValue);
        return true;
    }
    
    function enter(uint256 ticketCount) public {
        IERC20 tokenContract = IERC20(_tokenAddress);
        uint tokenAmount = ticketCount.mul(_ticketValue);
        require(tokenContract.transferFrom(msg.sender, address(this), tokenAmount));
        players.push(msg.sender);
        lotteryTokens = lotteryTokens.add(tokenAmount);
        for(uint i=0; i < ticketCount; i++) {
            lotteryList.push(msg.sender);
        }
        emit changeTotalTokens(lotteryTokens);
    }
    
    function pickWinner() public isManager isAnyPlayers {
        IERC20 tokenContract = IERC20(_tokenAddress);
        uint index1 = random(1);
        uint index2 = random(2);
        uint bonus = uint(lotteryTokens.div(3));
        winners[lotteryList[index1]] = winners[lotteryList[index1]] + bonus;
        winners[lotteryList[index2]] = winners[lotteryList[index2]] + bonus;
        firstWinner = lotteryList[index1];
        secondWinner = lotteryList[index2];
        tokenContract.transfer( 0x0000000000000000000000000000000000000000, lotteryTokens.sub(bonus.mul(2)) );
        
        players = new address[](0);
        lotteryList = new address[](0);
        lotteryTokens = 0;
        startTime = now;
        emit lotteryEnded(firstWinner, secondWinner, startTime);
    }
    
    function getBonus() public view returns(uint256) {
        return lotteryTokens.div(3);
    }
    
    function userBonus(address account) public view returns(uint256) {
        return winners[account];
    }
    
    function getBurn() public view returns(uint256) {
        return lotteryTokens.sub(lotteryTokens.div(3).mul(2));
    }

    function random(uint256 index) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now+index, lotteryList))).mod(lotteryList.length);
    }

    function withdraw() public isWinner payable returns(uint256) {
        IERC20 tokenContract = IERC20(_tokenAddress);
        
        uint bonus = winners[msg.sender];
        tokenContract.transfer( msg.sender, bonus );
        winners[msg.sender] = 0;
        emit transferBonus(msg.sender, bonus);
        return bonus;
    }
}