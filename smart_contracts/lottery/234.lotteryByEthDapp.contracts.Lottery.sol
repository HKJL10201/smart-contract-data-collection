pragma solidity ^0.8.9;

contract Lottery {
    // 1. 管理员
    // 2. 彩民 address[] players
    // 3. 当前期数: round 每期加一
    // 4. 中奖人: winner 
    // 在前端，可以通过访问函数得到manager，round，winner的信息
    // marager(),round(),winner()
    address public manager;
    address[] public players;
    uint256 public round;
    address public winner;
    constructor() public {
        manager = msg.sender;
    }
    // 1. 每个人可以多次，但每次只能投1ether
    function playe() payable public {
        require(msg.value ==1 ether);
        // 2. 把参与者加入到彩民池中
        players.push(msg.sender);
    }
    // 开奖函数;
    // 目标： 从彩民池（数组）中找到一个随机数彩民(找随机数)
    // 找到一个特别大的数(随机)，对我们的彩民数组长度求余数
    // 用hash值实现大的随机数
    // 哈希内容的随机，当前时间，区块的挖矿难道，彩民数量，作为输入
    function draw() onlyManager public {
        bytes memory v1 = abi.encodePacked(block.timestamp,block.difficulty,players.length);
        bytes32 v2 = keccak256(v1);
        uint256 v3 = uint256(v2);

        uint256 index = v3% players.length;

        winner = players[index] ;

        // uint256 memory money = address(this).balance * 90 / 100;
        // uint256 memory money1 = address(this).balance - money;
        uint256  money = address(this).balance * 90 / 100;
        uint256  money1 = address(this).balance - money;
        payable(address(uint160(winner))).transfer(money);
        payable(address(uint160(manager))).transfer(money1);
        round++;
        delete players;
    }
    // 退奖逻辑
    // 1. 遍历palyers 数组，逐一退
    // 2. 期数加一
    // 3. 彩民清零

    // 使用者花费手续费(管理员)
    function undraw() onlyManager public{
        for(uint256 i=0;i<players.length;i++){
            // players[i].transfer(1 ether);
            payable(address(uint160(players[i]))).transfer(1 ether);
        }
        round++;
        delete players;
    }
    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    // 获取彩民人数
    function getPlayersCount() public view returns(uint256){
            return players.length;
    }

    // 查询余额
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    // 获取彩民数组
    function getPlayers() public view returns(address[] memory){
        return players;
    }

}