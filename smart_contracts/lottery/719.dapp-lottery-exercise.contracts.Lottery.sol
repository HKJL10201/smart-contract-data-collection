// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//0x1F3bf7AAA58460b1767B3136748B48Be5dFBFC3C
contract Lottery {
    address public owner;
    address payable[] public managers;
    address payable[] public players;
    address public mokToken;
    uint public price;
    uint public prizePool;
    uint public pastPool;
    uint public usageFeePool;
    uint public lastWinner;
    uint public resetTime;
    
    constructor(address token) {
        owner = msg.sender;
        managers = new address payable[](2);
        mokToken = token;
        price = 20 * 10 ** 18;
        prizePool = 0;
        usageFeePool = 0;
        resetTime = 0;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    modifier staffOnly(){
        require(
                msg.sender == owner ||
                msg.sender == managers[0] ||
                msg.sender == managers[1]
        );
        _;
    }


    function enter() public payable{
        require(
            IERC20(mokToken).transferFrom(msg.sender, address(this), price)
        );
        players.push(payable(msg.sender));
        prizePool += price*95/100;
        usageFeePool += price*5/100;

    }

    function withdraw() public ownerOnly{
        IERC20(mokToken).transfer(msg.sender, usageFeePool);
        usageFeePool = 0;
    }

    function randomize() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public staffOnly{
        require(
            block.timestamp > resetTime
        );
        uint index = randomize() % players.length;
        players[index].transfer(prizePool);
        prizePool = 0;
        resetTime = block.timestamp + 1 days;
    }

    function getSummary() public view returns (
        address, uint, uint, uint, uint, uint
    ) {
        return (
            owner,
            price,
            prizePool,
            pastPool,
            lastWinner,
            resetTime
        );
    }
}