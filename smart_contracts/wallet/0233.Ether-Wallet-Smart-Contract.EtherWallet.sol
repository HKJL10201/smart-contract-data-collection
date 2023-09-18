// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
contract Wallet{
    address payable public owner;
    constructor(address _owner){
        owner=payable (_owner);
    }
    function deposit() public payable{
        require(msg.sender==owner,"Only Owner Can Deposit Ether");
    }//storing ether;
    function sendEther(address payable receiver,uint amount)public{
        require(msg.sender==owner,"Only owner can send ether to other account");
        amount=amount*10**18;//wei to ether
        receiver.transfer(amount);
    }
    function balanceof()public view returns(uint balance){
        return address(this).balance;
    }
    fallback()payable external{
        payable(msg.sender).transfer(msg.value);
    }
    receive()external payable {
        deposit();//For direct transfer from metamask
    }
}