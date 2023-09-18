// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
contract real2{
    mapping(address=>bool)  tc;
    uint public rcount=0;
    uint public dcount=0;

    function REPUBLIC()public payable{
        require(tc[msg.sender]==false && msg.value==1 ether,"address should sent only 1 ether");
      
        tc[msg.sender]=true;
        rcount++;

    }
    function DEMOCRATIC()public payable {
        require(tc[msg.sender]==false && msg.value==1 ether,"address should sent only 1 ether");
        tc[msg.sender]=true;
        dcount++;
    }


}