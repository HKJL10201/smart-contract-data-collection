pragma solidity ^0.4.0;

//0x8d29a3073301f1503e1657a1fdeb364d9a346009

contract Lottery {
    uint tokenNum = 1;
    uint exchageRate = 0.001 * 1 ether;
    uint tokenMax = 64;
    uint threshold = exchageRate * tokenMax;

    mapping(uint => address) tokens;
    
    function buyLottery() public payable {
        require(tokenNum<=tokenMax);
        require(msg.value % exchageRate == 0);
        tokenNum = tokenNum + msg.value / exchageRate;
        tokens[tokenNum] = msg.sender;
    }
    
    
    function chooseWinner() public {
        require(tokenNum>tokenMax);
        uint winner = uint(block.blockhash(block.number-1)) % tokenMax;
        while(tokens[winner]==0)
            winner ++;
        resetLottery();
        tokens[winner].transfer(threshold);
    }
    
    function tokensLeft() constant public returns(uint){
        return (tokenMax - tokenNum + 1);
    }
    
    function resetLottery() private{
        uint i = 0;    
        while(tokens[i]!=0){
            tokens[i]=0;
            i++;
        }
        tokenNum = 1;
    }
}
