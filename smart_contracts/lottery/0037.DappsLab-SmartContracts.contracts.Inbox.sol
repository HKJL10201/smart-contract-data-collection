pragma solidity ^0.8.0;

contract Inbox {
    uint256 public value;
    constructor(){

    }
    function set(uint256 player) public{
        value = player;
    }
    function get() public view returns(uint256){
        return value;
    }
}
