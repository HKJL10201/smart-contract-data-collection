//SPDX-License-Identifier:GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;
contract myWallet{
    address payable me;

    constructor(){
        me=payable(msg.sender);
    }

    receive() external payable{}

    function balanceCheck() external view returns(uint){
        return address(this).balance;
    }

    function cashout(uint _amount) external{
        require(msg.sender==me,"I can only call the method.");
        payable(msg.sender).transfer(_amount);
    }

}