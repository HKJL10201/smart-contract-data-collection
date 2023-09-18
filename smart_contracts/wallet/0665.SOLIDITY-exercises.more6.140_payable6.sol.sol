//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Deposit {
    string public myWord = "Flower";

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getAddress() external view returns(address) {
        return address(this);
    }
    //Contract -> Address(_to)
    function deposit(address payable _to) external payable {
        _to.transfer(55);
    }

    //Contract -> Address(_to)
    function deposit2(address payable _to) external payable {
        (bool success, ) = _to.call{value: 55}("");
        require(success, "failed to send ether");
    }

    //Function Caller -> Contract (but I need to use msg.value input field)
    function deposit3() external payable {
    }

    //ACCOUNT --> CONTRACT
    //Here the user must pass deposit value inside msg.value input area as well.
    //When you deploy this with website, then by using web3 function you wont need to deposit it.
    function depositUsingParameter() public payable { 
        require(msg.value > 1*(10**18));
    }

    //Function Caller -> Contract
    fallback() external payable{}
    receive() external payable{}

}
