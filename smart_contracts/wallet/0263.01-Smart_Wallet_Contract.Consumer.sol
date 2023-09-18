//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Consumer {
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function deposit() public payable {}
}
