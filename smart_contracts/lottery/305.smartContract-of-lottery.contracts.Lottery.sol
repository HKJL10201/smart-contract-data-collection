pragma solidity ^0.4.17;

contract Lottery{
    address public manager;//管理员
    address[] public players;//参与者
    address public winner; //中奖者
    //构造函数
    function Lottery() public{
        manager = msg.sender;
    }
    //获取管理员地址
    function getManager() public view returns(address){
        return manager;
    }
    //投注彩票
    function enter() public payable {
        require(msg.value == 1 ether);
        players.push(msg.sender);
    }
    //返回投注彩票的人
    function getPlayers() public view returns(address[]){
        return players;
    }
    //获取余额
    function getBalance() public view returns(uint){
        return this.balance;
    }
    //产生随机数
    function random() private view  returns (uint){
        return  uint(keccak256(block.difficulty, now, players));
    }
    //开奖，开奖必须要管理员执行
    function  pickWinner() public onlyManagerCanCall {
        uint index = random() % players.length;
        winner =  players[index];
        players = new address[](0) ;
        winner.transfer(this.balance);
    }
    //退款，退款必须要管理员执行
    function refund() public onlyManagerCanCall{
        for(uint i = 0;i<players.length;i++){
            players[i].transfer(1 ether);
        }
        players = new address[](0) ;
    }
    //抽取管理员执行方法
    modifier onlyManagerCanCall(){
        require(msg.sender == manager);
        _;
    }
}
