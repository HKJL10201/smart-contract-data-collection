pragma solidity ^0.4.24;

contract Lottery {
    address manager;  // 管理员
    address[] players;  // 投了注的彩民
    address winner;   // 上期彩票的胜出者
    uint256 round = 1;    // 第几期
    
    constructor() public {
        manager = msg.sender;
    }
    
    // 修饰器，限定只有管理员才有权操作
    modifier onlyManager() {
        require(manager == msg.sender);
        _;
    }
    
    
    // 投注
    function play() public payable {
        // 限定投足金额为1eth
        require(msg.value == 1 ether);
        players.push(msg.sender);
    }
    
    // 开奖
    function kaiJIang() public onlyManager {
        // 1.设置Winner
        // 生成随机下标
        bytes memory v1 = abi.encodePacked(block.difficulty, now, players.length);
        bytes32 v2 = keccak256(v1);
        uint v3 = uint256(v2) % players.length;
        winner = players[v3];
        // 2.把奖池的金额转账给winner
        winner.transfer(address(this).balance);
        // 3.清空plays
        delete players;
        // 4.期数加1
        round++;
    }
    
    // 退奖
    function tuiJiang() public onlyManager {
        require(players.length != 0);
        // 1.把奖池的金额退还给每一个玩家
        for (uint i = 0; i < players.length; i++) {
            players[i].transfer(1 ether);
        }
        // 2.清空plays
        delete players;
        // 3.期数加1
        round++;
    }
    
    // 获取奖金池的金额
    function getAmount() public view returns(uint256) {
        return address(this).balance;
    }
    
    // 获取管理员地址
    function getManagerAddress() public view returns(address) {
        return manager;
    }
    
    // 返回当前期数
    function getRound() public view returns(uint256) {
        return round;
    }
    
    // 返回中奖者地址
    function getWinner() public view returns(address) {
        return wget
    }
    
    // 返回参与彩民的地址
    function getPlays() public view returns(address[]) {
        return players;
    }
    
}