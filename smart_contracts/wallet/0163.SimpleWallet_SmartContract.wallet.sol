//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract Example{
    mapping(address=>uint) public User;

    function Deposit()payable public{
        User[msg.sender]+=msg.value;
    }

    function Withdraw()public payable{
        uint data=User[msg.sender];
        User[msg.sender]=0;
        payable(msg.sender).transfer(data);

    }

    function Send(address payable _user) public{

        uint value=User[msg.sender];
        User[msg.sender]=0;
        _user.transfer(value);

    }

    function ContractBalance() public view returns(uint){

        return address(this).balance; 
    }

}
