// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './Mtoken.sol';

contract Mswap {
    string public name;
    uint public rate;
    Mtoken public mtoken;
    
    
    constructor(address _mtoken) {
        name = "Mswap Exchange";
        rate = 100;
        mtoken = Mtoken(_mtoken);
    }

    event TransactionInfo(
        string transactionType,
        address user,
        string tokenName,
        string tokenSymbol,
        address tokenAddress,
        uint amount,
        uint date,
        uint rate
    );


    function buyToken() external payable {
        uint amount = msg.value * rate;
        mtoken.transfer(msg.sender, amount);
        emit TransactionInfo("PURCHASE",msg.sender, mtoken.name(), mtoken.symbol(), address(mtoken), amount, block.timestamp, rate);
    }

    function sellToken(uint _amount) external {
        mtoken.transferFrom(msg.sender, address(this), _amount);
        uint etherAmount = _amount / rate;
        require(address(this).balance >= etherAmount, "sorry we don't have ether for that amount at the moment");
        payable(msg.sender).transfer(etherAmount);
        emit TransactionInfo("SOLD",msg.sender, mtoken.name(), mtoken.symbol(), address(mtoken), _amount, block.timestamp, rate);
    }

}