//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 < 0.9.0;

contract Mapping{

    mapping(address => uint) public bids;

    function bid() payable public {

        bids[msg.sender] = msg.value;

    }


}