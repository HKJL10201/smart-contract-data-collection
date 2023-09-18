pragma solidity ^0.4.24;

interface Auction{
    // interface are used to just declare the function signatures
    function bid() external payable;
    function end() external;
}
