// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    // address public manager;
    // address payable[] public participants;

    uint[3] public balance = [1, 2, 3];

    function checkLength() public view returns (uint){

        return balance.length;
    }

    
}