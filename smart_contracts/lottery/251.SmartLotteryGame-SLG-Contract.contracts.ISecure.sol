pragma solidity ^0.5.8;


interface ISecure {
    function getRandomNumber(uint8 _limit, uint8 _totalPlayers, uint _games, uint _countTxs)
    external
    view
    returns(uint);

    function checkTrasted() external payable returns(bool);
}
