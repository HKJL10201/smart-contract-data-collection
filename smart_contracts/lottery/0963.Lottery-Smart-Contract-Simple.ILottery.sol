pragma solidity ^0.5.0;

interface ILottery {
    function newGame(uint256[] calldata prizes) external;
}