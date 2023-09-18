pragma solidity ^0.4.24;

contract Lottery {
    // 1.管理员：负责开奖和退奖
    // 2.彩民池：address [] player
    // 3.当前期数：round，每期结束后加1
    // 4.当期赢家
    // 在前端可以通过访问函数得到manager，round，winner的信息
    
    address public manager;
    address[] public players;
    uint256 public round ;
    address public winner;
    
    constructor() public{
        manager = msg.sender;
    }
    
    // 投注函数
    
    function play()payable public{
        // 1.每个人可以投多次，每次1ether
        
        require(msg.value == 1 ether);
        // 2.把参与者加入到彩民池中
        
        players.push(msg.sender);
        
    }
    
    modifier onlyManager(){
        require(msg.sender == manager);
        _;
    }
    
    // 开奖函数（管理员）
    
    function runLottery() onlyManager public{
        require(players.length != 0);
        bytes memory v1 = abi.encodePacked(block.timestamp,block.difficulty,players.length);
        bytes32 v2 = keccak256(v1);
        uint256 v3 = uint256(v2);
        
        
        uint256 index = v3 % players.length;
        winner = players[index];
        uint256 money = address(this).balance * 90 / 100;
        uint256 money1 = address(this).balance - money;
        
        winner.transfer(money); 
        manager.transfer(money1);
        
        round++;
        delete players;
    }
    
    // 退奖函数（管理员）
    
    function returnLottery() onlyManager public {
        require(players.length != 0);
        for (uint256 i = 0; i < players.length;i++) {
            players[i].transfer(1 ether);
        }
        
        round ++;
        delete players;
        
    }
    
    
    // 获取投注总金额
    
    function getBalnace() public view returns(uint256){
        return address(this).balance;
    }
    
    // 获取参与投注的彩民
    
    function getPlayers() public view returns(address[]){
        return players;
    }
    
    // 获取参与投注的彩民人数
    
    function getPlayerCounts() public view returns(uint256){
        return players.length;
    }
    
}


