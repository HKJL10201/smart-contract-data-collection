// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Wallet {
    address private owner;
    mapping(address => uint256) public balances;
   event Withdrawal(address account,uint256 amount);
   event Transfer(address from ,address to, uint256 amount);
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner,"Not owner");
        _;
    }
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount,"insufficient ether balance");
        balances[msg.sender] -= amount;
         payable(msg.sender).transfer(amount);
         emit Withdrawal(msg.sender,amount);
    }

    function Contractbalance() public view  returns(uint256){
           return address(this).balance;
    }
    function destroy(address payable addr) public  onlyOwner{
        selfdestruct(addr);
    }
    function transfer(address to ,uint amount) public {
        require(balances[msg.sender] >= amount,"insufficient ether balance");
        balances[msg.sender] -= amount;
        balances[to]+= amount;
        emit Transfer(msg.sender,to,amount);

    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}

//Author christopher promise....