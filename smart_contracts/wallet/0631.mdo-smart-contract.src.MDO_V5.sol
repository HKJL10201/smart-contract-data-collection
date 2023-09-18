pragma solidity >0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // if (a == 0) {
        //     return 0;
        // }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes  _extraData) external; 
    
}

contract TokenERC20 is Ownable {
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals = 6;  // decimals 可以有的小数点个数，最小的代币单位。18 是建议的默认值
    uint256 public totalSupply;
    
    // 用mapping保存每个地址对应的余额
    mapping (address => uint256) public balanceOf;
    // 存储对账号的控制
    mapping (address => mapping (address => uint256)) public allowance;

    // 事件，用来通知客户端交易发生
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 事件，用来通知客户端代币被消费
    event Burn(address indexed from, uint256 value);

    /**
     * 初始化构造
     */
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
        balanceOf[msg.sender] = totalSupply;                // 创建者拥有所有的代币
        name = tokenName;                                   // 代币名称
        symbol = tokenSymbol;                               // 代币符号
    }

    /**
     * 代币交易转移的内部实现
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        // 检查发送者余额
        require(balanceOf[_from] >= _value);
        // 确保转移为正数个
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // 以下用来检查交易，
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     *  代币交易转移
     * 从创建交易者账号发送`_value`个代币到 `_to`账号
     *
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * 账号之间代币交易转移
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * 设置某个地址（合约）可以交易者名义花费的代币数。
     *
     * 允许发送者`_spender` 花费不多于 `_value` 个代币
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 设置允许一个地址（合约）以交易者名义可最多花费的代币数。
     *
     * @param _spender 被授权的地址（合约）
     * @param _value 最大可花费代币数
     * @param _extraData 发送给合约的附加数据
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * 销毁创建者账户中指定个代币
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * 销毁用户账户中指定个代币
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function test() public view returns(uint256,uint256,uint8){
       uint256 baseMintedAmount = 80;
       uint256 durat = block.timestamp.sub(1611309504);
      // uint8  times =  uint8(durat.div(200)) * 2;
       uint256  times =  durat.div(200) * 2;
      //uint8 times2 = times * 2;
       baseMintedAmount = baseMintedAmount.div(times);
      // return (uint8(baseMintedAmount),durat,times);
       return (baseMintedAmount,durat,uint8(times));
      //return (0,durat,0);
    }
    
       address MDong;
       struct UserPledeg{
        uint256 PledegId; //抵押ID
        uint256 start; //抵押开始时间
        uint256 time;  //抵押期限
        uint256 amount; //用户抵押量
       }
    
       struct RecordBean {
	     // 表名称
	     string tableName;

	     // 内容值
	     UserPledeg[] userp;
       }
    
     mapping(address=>RecordBean) Usermap;
     RecordBean public rec;
     mapping(address => uint256)  public pledgeID;//抵押ID
  
    function SetUserPledgeData(address addr, uint256 time, uint256 starttime2,uint256 amount) public returns (uint256) {
     UserPledeg memory  cources;
     cources.start = starttime2;
     cources.time = time;
     cources.amount = amount;
     cources.PledegId =  pledgeID[addr]++;
     rec.userp.push(cources);
     rec.tableName = "test";

     Usermap[addr] = rec;// RecordBean({"tableName":"test","UserPledeg":rec.userp});
     return  cources.PledegId;
  }
  
 //质押MDO
function PledgeMDO(uint256 amount ,uint256 time) public view returns(uint256,uint256) {
         //预言机抽取入场时候的精准价格
          require(MDong != address(0x0));
        // 检查发送者余额
        require(balanceOf[msg.sender] >= amount);
        // 确保转移为正数个
        require(balanceOf[MDong] + amount > balanceOf[msg.sender]);

        // 以下用来检查交易，
        uint previousBalances = balanceOf[msg.sender] + balanceOf[MDong];
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        balanceOf[MDong] = balanceOf[MDong].add(amount);
        
        emit  Transfer(msg.sender, owner, amount);
        
        assert(balanceOf[MDong] + balanceOf[msg.sender] == previousBalances);
      
         //记录用户抵押情况 抵押期限,抵押开始时间,抵押数量
         uint256 id =  SetUserPledgeData(msg.sender,time,block.timestamp,amount);
         return (block.timestamp,id);
    }
    
    //赎回
    function refund(uint id) public returns(uint256) {
         RecordBean memory record =  Usermap[msg.sender];
         UserPledeg memory tmptmp;
         uint256 starttime;
         uint256 time;
         uint256 amount;
          for(uint i = 0; i < rec.userp.length; i++) {
            tmptmp =  rec.userp[i];
            if (tmptmp.PledegId == id){
              starttime =  tmptmp.start;
              time = tmptmp.time;
              amount =  tmptmp.amount;
            }
        }
        
        uint256 tmpDur = block.timestamp.sub(starttime);
        assert(tmpDur > time);
        amount =  amount * 10 ** uint(decimals);
          
      //计算收益
      uint256   profit; //收益
      uint256   fee;
      //根据质押期计算
         if (time == 86400) { //1%
          profit =  (amount.mul(1 * 10**uint(decimals))).div(100* 10**uint(decimals));
        
         } else if (time == 604800 ){
              profit =  (amount.mul(8 * 10**uint(decimals))).div(100* 10**uint(decimals));
         }else if(time == 1296000){
              profit =  (amount.mul(18 * 10**uint(decimals))).div(100* 10**uint(decimals));
         }else if (time == 2592000 ){
              profit =  (amount.mul(30 * 10**uint(decimals))).div(100* 10**uint(decimals));
         }else{
            //profit1 =  (amount.mul(1 * 10**uint(decimals))).div(100* 10**uint(decimals)); //test
             return 0;
         }
     // 实际收益
      profit =  (profit.mul(85 * 10**uint(decimals))).div(100* 10**uint(decimals));
      
      //手续费
      fee = (profit.mul(5 * 10**uint(decimals))).div(100* 10**uint(decimals));
      
      removeAtIndex(msg.sender,tmptmp.PledegId);
      return profit;
    }
    
 //删除指定索引的数组元素
function removeAtIndex(address addr,uint index) public   {
     RecordBean a=  Usermap[addr];
    if (index >= a.userp.length) return;
 
    for (uint i = index; i < a.userp.length-1; i++) {
      a.userp[i] = a.userp[i+1];
    }
 
    delete a.userp[a.userp.length-1];
    a.userp.length--;
 }
    
}

////////////////////////////////

//排单池
contract Queue
{
    struct order{
        address addr;
        uint256 value; 
        uint256 time;
    }
    
	
	uint256 public  head = 1;
	uint256 public  last = 0;
	mapping(uint256 => order) public mapqueueOrder;
	
    function push( address addr, uint256 value,uint256 time) public
    {
    	last += 1;
		mapqueueOrder[last] = order(addr,value,time);
    }
    
    function pop() public returns (address addr,uint256 value,uint256 time) {
		require(last >= head, "Queue is Empty");
		order  tmpdata;
		tmpdata = mapqueueOrder[head];
		addr = tmpdata.addr;
		value =  tmpdata.value;
		time = tmpdata.time;
		delete mapqueueOrder[head];
		head += 1;
	}
}

contract StringToBytes{
  function StringToBytesVer1(string memory source) returns (bytes result) {
    return bytes(source);
  }
}

//抵押池
contract DelegatebwPool {
     address  public MODaddr = address(0x276411191c378D4616133A6FE1B4F5cB5917df21);//魔塔;
        TokenERC20 token;
       function setContract(address _tokenAddress) public {
 	   token = TokenERC20(_tokenAddress);
    	}
    	
    	function getBalance(address _tokenAddress)  public view returns (uint256 ) {
	     uint256 amount1 = token.balanceOf(address(this));
	     return amount1;
    	}
    	
    	function TransferMod(uint256 amount) public {
    	     uint256 contractToken = token.balanceOf(this);
             assert(contractToken >= amount);
             token.transfer(MODaddr, amount); 
   }
   
      function setModContract(address _modAddress) public {
 	   MODaddr = _modAddress;
    	}
}

//给魔塔转300万，每天最多滑落10万
contract Mouta is StringToBytes {
     using SafeMath for uint256;
  //  mapping(address => uint256) order;
    uint256 public totalPledge; //总质押
    uint256 public toDayPledge; //今日抵押量
   // Queue OrderPool; //排单池
   uint256 public totalOrderPool;
   address  public PledgePool = address(0x276411191c378D4616133A6FE1B4F5cB5917df21);//抵押池;

     // 取当前合约的地址
	function getAddress() public view returns (address) {
		return address(this);
	}
	
	function getBalance(address _tokenAddress)  public view returns (uint256 ) {
	    TokenERC20 token = TokenERC20(_tokenAddress);
	    uint256 amount1 = token.balanceOf(address(this));
	    return amount1;
	}
	
	TokenERC20 token;
	function setContract(address _tokenAddress) public {
	   token = TokenERC20(_tokenAddress);
	}
	
	DelegatebwPool deletgatePool;
	function setDelegateContract(address _constractAddress) public {
	   deletgatePool = DelegatebwPool(_constractAddress);
	}
	
	function setPledgePool(address addr) public {
	   PledgePool = addr;
	}
	
	function PledgeUSDT(address src,uint256 value,uint256 time) public  returns(uint256,uint256) {
	     uint256 starttime;
	     uint256 id;
	     return _PledgeUSDT(src,value,time);
	 }
	 
    function _PledgeUSDT(address src,uint256 value,uint256 time) internal  returns(uint256,uint256) {
     //今日抵押总数是否达到上限
    //require(toDayPledge < 100000,"The total amount of mortgage has reached the upper limit today");
     //判断时进入排单池还是抵押池
     //根据当日魔塔掉落数量不超过10w,如果超过则进入派单
     //计算还能抵押的数量
    // uint256 OrderqueueCnt;
     uint256 amount;
     uint256 remainder =  100000 - toDayPledge;
    if (value > remainder){
        require(toDayPledge < 100000,"The total amount of mortgage has reached the upper limit today");
         //OrderqueueCnt = value - remainder;
         amount = remainder;
     }else{
         amount = value;
     }
    
      //进入抵押池
      uint256 contractToken = token.balanceOf(this);
      assert(contractToken > amount);
      token.transfer(PledgePool, amount); 
      totalPledge += amount;
      toDayPledge += amount; //今日抵押数
      
      //记录用户抵押情况 抵押期限,抵押开始时间,抵押数量
     uint256 id =  SetUserPledgeData(src,time,block.timestamp,amount);
     
    //  //排单
    //  if (OrderqueueCnt > 0){
    //      PushPool(src,OrderqueueCnt,time); 
    //  }
     
    return(block.timestamp,id);
  }
  
    function GetToDayDelegatebwCnt() public view returns (uint256){
      return toDayPledge;
      
  }
  
//   	//进入排单池
// 	function PushPool(address addr,uint256 value,uint256 time) public{
// 	    push(addr,value,time); //进入排单池
// 	}
	
    // function PopPool() public constant returns(address,uint256){
    //  var (addr,value,time) = pop();
    //  return (addr,value);
    // }
 
   struct UserPledeg{
        uint256 PledegId; //抵押ID
        uint256 start; //抵押开始时间
        uint256 time;  //抵押期限
        uint256 amount; //用户抵押量
    }
    
   struct RecordBean {
	// 表名称
	string tableName;

	// 内容值
	UserPledeg[] userp;
}

  mapping(address=>RecordBean) Usermap;
 
  RecordBean public rec;

  mapping(address => uint256)  public pledgeID;//抵押ID

  function SetUserPledgeData(address addr, uint256 time, uint256 starttime2,uint256 amount) public returns (uint256) {
     UserPledeg memory  cources;
     cources.start = starttime2;
     cources.time = time;
     cources.amount = amount;
     cources.PledegId =  pledgeID[addr]++;
     rec.userp.push(cources);
     rec.tableName = "test";
    // RecordBean  temp = RecordBean( rec.tableName,rec.userp);
    
     Usermap[addr] = rec;// RecordBean({"tableName":"test","UserPledeg":rec.userp});
    //  Usermap[addr] = temp; 
     return  cources.PledegId;
  }
  
 struct Profit{
     uint256   userprofit; //收益
     uint256   profit;
     uint256   poolprofit; //收益
     uint256   fee;
 }
 
//赎回
function ReFund(address addr,uint256 id)public returns(uint256,uint256,uint256){
    //是否到期
     RecordBean memory rec =  Usermap[addr];
     UserPledeg memory tmptmp;
     uint256 starttime;
     uint256 time;
     uint256 amount;
       uint256 decimals  = 6;
    for(uint i = 0; i < rec.userp.length; i++) {
            tmptmp =  rec.userp[i];
            if (tmptmp.PledegId == id){
              starttime =  tmptmp.start;
              time = tmptmp.time;
              amount =  tmptmp.amount;
            }
        }
    
         uint256 tmpDur = block.timestamp.sub(starttime);
         assert(tmpDur > time);
          amount =  amount * 10 ** uint(decimals);
      // testval = amount;
     // return testval;
       //计算收益
      // uint256   profit; //收益
     //  uint256   Poolprofit; //收益
      // uint256   fee;
       Profit memory profit;
      // 根据质押期计算收益率

         if (time == 86400) { //1%
          profit.profit =  (amount.mul(1 * 10**uint(decimals))).div(100* 10**uint(decimals));
        
         } else if (time == 604800 ){
              profit.profit =  (amount.mul(8 * 10**uint(decimals))).div(100* 10**uint(decimals));
         }else if(time == 1296000){
              profit.profit =  (amount.mul(18 * 10**uint(decimals))).div(100* 10**uint(decimals));
         }else if (time == 2592000 ){
              profit.profit =  (amount.mul(30 * 10**uint(decimals))).div(100* 10**uint(decimals));
         }else{
           // profit1 =  (amount.mul(1 * 10**uint(decimals))).div(100* 10**uint(decimals)); //test
            return (0,0,0);
         }
        
      //  实际收益
      profit.userprofit =  (profit.profit.mul(85 * 10**uint(decimals))).div(100* 10**uint(decimals));
      //排单池收益
     profit.poolprofit =  (profit.profit.mul(10 * 10**uint(decimals))).div(100* 10**uint(decimals));
      //手续费
      profit.fee = (profit.profit.mul(5 * 10**uint(decimals))).div(100* 10**uint(decimals));
       
      //币返回魔塔
      deletgatePool.TransferMod(amount);
      removeAtIndex(addr,tmptmp.PledegId);
     return (profit.userprofit,profit.poolprofit,profit.fee);
       //从排单池到抵押池
   // var(addr1,amount1,time1) = PopPool();
   
   //  _PledgeUSDT(addr1,amount1,time1);
}

 //删除指定索引的数组元素
function removeAtIndex(address addr,uint index) public   {
     RecordBean  a=  Usermap[addr];
    if (index >= a.userp.length) return;
 
    for (uint i = index; i < a.userp.length-1; i++) {
      a.userp[i] = a.userp[i+1];
    }
 
    delete a.userp[a.userp.length-1];
    a.userp.length--;
 }

function getdata(address addr,uint j) public view returns (uint256 starttime,uint256 time,uint256 amount,uint256 ID){
  RecordBean a=  Usermap[addr];
    UserPledeg tmptmp;
    tmptmp = a.userp[j];
  return (tmptmp.start,tmptmp.time,tmptmp.amount,tmptmp.PledegId);
}

function getLenth(address addr) public view returns(uint) {
    RecordBean a=  Usermap[addr];
    return a.userp.length;
}

  	 function PledgeMDO(address src,uint256 value,uint256 time) public  returns(uint256,uint256) {
	   
	 }
}


