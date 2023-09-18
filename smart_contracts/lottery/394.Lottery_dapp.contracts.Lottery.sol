pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    string public message;
    function Lottery(string _message)public{
        message = _message;
        manager = msg.sender;//创建合约的时候自动地进行赋值
    }
    function getMessage() public view returns(string){ //获取信息
        return message;
    }
    function get_manager()public view returns(address){
        return manager;
    }
    //投注函数
    function enter() public payable{
        require(msg.value == 1 ether);
        players.push(msg.sender);
    }
    //查询使用者地址
    function queryplyers() public view returns(address[]){
        return players;
    }
    //获取当前合约内的金钱数量
    function getbalance() public view returns(uint){
        return this.balance;
    }
    function getplayercounts()public view returns(uint){
        return players.length;
    }
    function random() private view returns(uint){             //private用以私密化该函数从而只能被别的函数所调用
        return uint(sha256(block.difficulty,now,players));
    }
    function getresult()public onlymanagercancall returns(address){
        uint result = random() % players.length;
        address winner =  players[result];
        winner.transfer(this.balance);             //使用合约内的金钱打钱
        players = new address[](0);
        return winner;
    }
    function refund()public onlymanagercancall{
        for (uint i; i<players.length;i++){       //通过数组的内建函数来控制转账
            players[i].transfer(1 ether);
            players = new address[](0);
        }
    }
    modifier onlymanagercancall(){                //
        require(msg.sender == manager);
        _;
    }
}
