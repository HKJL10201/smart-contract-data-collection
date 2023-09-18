// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Wallet {
    address payable[] public accounts;
    address payable public owner;

        constructor(address _owner) {
            owner = payable(_owner);
            accounts.push(payable(owner));
        }

        function deposit() public payable {
        }
        function sendEther(address _to,uint _amount) public payable {
            require(owner==msg.sender,"sender is not allowed");
            payable(_to).transfer(_amount);
        }
        function balanceOf() public view returns(uint) {
            return address(this).balance;
        }
}
