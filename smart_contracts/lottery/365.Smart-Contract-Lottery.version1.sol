pragma solidity ^0.4.0;

//0x557a8a60ed8bf997cdcda1366c146609a4adea42

contract Lottery {
    uint tokenNum = 0;
    uint exchageRate = 0.001 ether;
    uint tokenMax = 64;
    uint threshold = exchageRate * tokenMax;
    
    mapping(uint=>address)tokens;

    function buyLottery() public payable returns(uint amount){
        uint refund = 0;
        bool reachedThreshold = (this.balance - msg.value % exchageRate) >= threshold;
        if(reachedThreshold)
            refund = this.balance - threshold;
        else
            refund = msg.value % exchageRate;
        amount = (msg.value - refund) / exchageRate;
        
        for(uint i=tokenNum;i<tokenNum+amount;i++)
            tokens[i] = msg.sender;
        tokenNum = (amount +tokenNum);
        
        if(reachedThreshold){
            uint winner =  uint(block.blockhash(block.number-1)) % tokenMax;
            tokenNum = 0;
            tokens[winner].transfer(threshold);
        }
        msg.sender.transfer(refund);
    }
    
    function tokensLeft() constant public returns(uint){
        return (tokenMax - tokenNum);
    }
}
