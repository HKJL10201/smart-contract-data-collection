// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./LotteryGame.sol";
import "./Lottery.sol";

contract Deployer {
    uint256 price = 10; //ticket price in wei
    uint256 M = 2; // duration of a round (n° blocks)
    uint256 K = 2; //paramater for random number generator
    address public lottery_operator;
    address public nft_address;
    LotteryGame item;
    Lottery lottery;

    constructor(address nft_addr, address lottery_op) {
        nft_address = nft_addr;
        lottery_operator = lottery_op;
    }

    function getLotteryAddress() public view returns (address) {
        return address(lottery);
    }

    function createLottery() public returns (address) {
        lottery = new Lottery(price, M, K, nft_address, lottery_operator);
        return address(lottery);
    }
}
