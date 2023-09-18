//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {

    function getEther() external payable{}

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    //This is a great function. It transfers all ether inside
    //this contract to any address. In this case the address is the msg.sender
    function withdraw() external {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    //The same function as above. But this time we are using function parameters
    //to send a specific amount of ether.
    function withdraw2(uint _amount) external {
        address payable _owner = payable(msg.sender);
        _owner.transfer(_amount);
    }

    //The same function as above. But this time we are using function parameters
    //to define the address.
    function withdraw3(address receiver, uint _amount) external {
        address payable _owner = payable(receiver);
        _owner.transfer(_amount);
    }
}

contract B {
    //This function works. It works together with getEther function. 
    function foo(address otherContract, uint _value) external payable {
       A(otherContract).getEther{value: _value}();
    }

    //This function does not work.
    function foo2(address otherContract, uint _value) public payable {
       (bool success, ) = otherContract.call{value: _value}("");
       require(success, "failed");
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    fallback() external payable{}
    receive() external payable{}
}