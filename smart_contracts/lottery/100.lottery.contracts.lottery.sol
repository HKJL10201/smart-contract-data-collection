pragma solidity ^0.4.24;

contract Lotty {
    // 1. 管理员:负责开奖和提奖
    address public manager;
    // 2. 彩民池: address[] players
    address[] public players;
    // 3. 当前期数: round,每期结束后加一
    uint256 public round;
    // 4. 中奖用户
    address public winner;

    constructor() public{
        manager = msg.sender;
    }

    // 实现投注函数
    // 1.每个人可以投多次
    function play() public payable{
        require(msg.value == 1 ether);
        // 2.把参与者加入到彩民池中
        players.push(msg.sender);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getPlayers() public view returns(address[]){
        return players;
    }


    // 实现中奖函数
    // 需求:从players中找到一个随机彩民(找一个随机数)
    //  1.找一个大的数,对我们的players数组求余
    //  2.用哈希数值实现大的随机数
    //  3.哈希内容的随机: 当前时间,区块挖矿难度,彩民数量,作为输入  keccak256 / abi.encodePacked

    function kaiJiang() public {
        bytes memory v1 = abi.encodePacked(block.timestamp,block.difficulty,players.length);
        bytes32 v2 = keccak256(v1);
        uint256 v3 = uint256(v2);
        uint256 index = v3 % players.length;
        winner = players[index];
        
        uint256 money = address(this).balance * 90 / 100;
        uint256 money1 = address(this).balance - money;
        
        winner.transfer(money);
        manager.transfer(money1);
        
        delete players;
        
        
    }


}