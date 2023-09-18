//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Deposit{

    address admin;

    constructor(){
        admin = msg.sender;
    }

    modifier onlyAdmin{
       require (admin == msg.sender);
        _;
    }
    receive() external payable{

    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function sendBalance(address payable _depositAdress) public payable onlyAdmin{
       // require(msg.sender == admin, "Error You are not the admin");
        _depositAdress.transfer(getBalance());
    }
}