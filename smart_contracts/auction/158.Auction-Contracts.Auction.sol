pragma solidity 0.5.11;

interface Auction {
    function bid() external payable;
    function end() external;
}
