pragma solidity ^0.4.25;


interface PoolingIF {
    function pooling(uint amount) external payable;
}

contract Test {
    address public poolCtx;

    function setPoolIF(address addr) public {
        poolCtx = addr;
    }

    function pooling() public payable {
        PoolingIF(poolCtx).pooling.value(msg.value)(msg.value);
    }
}


contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}


contract BonusPool is  Ownable,PoolingIF {
    
    using SafeMath for uint;
    
    event Withdraw(address indexed player, uint value);
    event PoolIncome(address indexed game, uint value);
    event SendBonus(address indexed to,uint value);
    
    address public developer;

    mapping(address => uint) private _addressTotalBalance;  /// 每个地址的已提取总额 
    mapping(address => uint) private _balance;              /// 每个地址可提取的额度 
    mapping(address => bool) private _blackList;            /// 无法提现的地址名单 
    
    uint256 public totalBonus;                              /// 用于显示分红池总额 owner可设置  
    /// totalPayment
    uint256 public totalPayment = 0;                        /// 累计可用分红池总额 真实金额 
    
    constructor() public {
        developer=msg.sender;
    }

    modifier onlyDev() {
        require(msg.sender == developer);
        _;
    }
    function setDev(address _dev) public onlyOwner {
        developer = _dev;
    }
    
    /// game
    uint public gameID;
    struct GameInfo {
        uint amount;                                      
        uint count;
        uint income;
        uint id;
        bool ok;
    }
    mapping(address => GameInfo)  gameInfo;                   
    mapping(uint => address) id2game;
    uint public income;

    function setGame(address game, bool ok) public onlyOwner {      /// onwer分配gameID
        GameInfo storage info = gameInfo[game];
        info.ok = ok;
        if (info.id == 0) {
            gameID++;
            info.id = gameID;
            id2game[gameID] = game;
        }
    }
   
    modifier onlyGame {
        if (gameInfo[msg.sender].ok) {
            _;
        } else {
            income = income.add(msg.value);
        }
    }
    
    function getGame(address game) public onlyGame returns (uint,uint,uint,uint,bool) {
        GameInfo storage info = gameInfo[game];
        return (info.id,info.amount,info.income,info.count,info.ok);
    }
    /// end game
    
    /// owner withdraw
    function superWithdraw(address to,uint256 amount) public onlyOwner{
        if(amount==0){
            amount=_balance[to];
            _balance[to]=0;
        }else{
            _balance[to]=_balance[to].sub(amount);
        }
        totalPayment = totalPayment.sub(amount);
        if (totalBonus>=amount){
            totalBonus = totalBonus.sub(amount);
        }else{
            totalBonus = 0;
        }
        _addressTotalBalance[msg.sender]=_addressTotalBalance[msg.sender].add(amount);
        
        to.transfer(amount);
    }
    
    function balance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }
    
    function superBonus(uint256 amount) public onlyOwner{
        if(amount==0){
            amount=totalPayment;
        }

        totalPayment=totalPayment.sub(amount);
        if (totalBonus>=amount){
            totalBonus = totalBonus.sub(amount);
        }else{
            totalBonus = 0;
        }
        _addressTotalBalance[msg.sender]=_addressTotalBalance[msg.sender].add(amount);

        msg.sender.transfer(amount);
    }
    /// end
    
    /// 用户查询累计提取金额 
    function getTotalBonusOf(address to) public view returns (uint256){
        return _addressTotalBalance[to];
    }
    
    function setTotalBonus(uint256 balance) public onlyOwner{
        totalBonus=totalBonus.add(balance);
    }
    
    
    /// 用户提现 
    function withdraw() external returns (bool) {
        require(check(msg.sender));
        require(_balance[msg.sender]>0);
        
        _transfer(msg.sender, _balance[msg.sender]);
        
        return true;
    }

    function _transfer(address to, uint256 value) private {
        require(to != address(0));

        totalPayment = totalPayment.sub(value);
        if (totalBonus>=value){
            totalBonus = totalBonus.sub(value);
        }else{
            totalBonus = 0;
        }
        
        _balance[to] = _balance[to].sub(value);
        
        to.transfer(value);
        
        _addressTotalBalance[to]=_addressTotalBalance[to].add(value);
        
        emit Withdraw(to, value);
    }
    /// end
    
    function pooling(uint256 value) payable external onlyGame{
        
        require(msg.value==value);
        
        totalPayment = totalPayment.add(value);
        totalBonus = totalBonus.add(value);
        GameInfo storage info = gameInfo[msg.sender];
        info.amount = info.amount.add(value);
        emit PoolIncome(msg.sender,value);
        
    }
        
    
    /// 将奖金发给玩家账户 
    function sendBonus(address[] to, uint256[] value) public onlyDev{
        require(to.length==value.length);
        for (uint i=0; i<to.length;i++){
            if (value[i]>0 && totalPayment > value[i]){
                _balance[to[i]]=_balance[to[i]].add(value[i]);
                emit SendBonus(to[i],value[i]);
            }
        }
        
    }
    
    /// end
    function getBanlance(address to) public view returns (uint256){
        return _balance[to];
    }
    /// end set bonus
    
    /// authorze
    bool authorizeMode = true;
    
    function setAuthorizeMode(bool state) public onlyOwner {
        authorizeMode = state;
    }
    
    function setPrivilege(address addr) public onlyOwner {
        _blackList[addr] = true;
    }
    
    function check(address to) internal view returns (bool) {
        if (!authorizeMode) {
            return true;
        }
        return (!_blackList[to]);
    }
    /// end authorize
}