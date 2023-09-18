pragma solidity ^0.4.24;

//interface外部合约
interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;}

contract TokenERC20 {
    // 公共变量，指定变量类型
    string public name;   //代币名称
    string public symbol; //代币符号位
    uint8 public decimals = 18; //代币最小单位，建议使用
    uint256 public totalSupply; //代币发行总数

    // 记录所有账户余额映射
    mapping(address => uint256) public balanceOf;
    // 设置最大交易量映射（避免大金额交易）
    mapping(address => mapping(address => uint256)) public allowance;

    // 交易事件：在区块链上创建一个event，用以通知客户端
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 减去用户余额事件
    event Burn(address indexed from, uint256 value);


    /* 初始化合约，并且把初始的所有代币都给这合约的创建者
     * @param initialSupply 代币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */
    //跟合约名字相同的函数是初始函数,理解成 init 函数即可
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        //以太币是10^18，后面18个0，所以默认decimals是18
        balanceOf[msg.sender] = totalSupply;
        //给指定帐户初始化代币总量，初始化用于奖励合约创建者
        name = tokenName;
        symbol = tokenSymbol;
    }

    /**
     * 私有方法从一个帐户发送给另一个帐户代币
     * @param  _from address 发送代币的地址
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        //避免转帐的地址是0x0,因为0x0地址代表销毁
        require(balanceOf[_from] >= _value);
        //检查发送者是否拥有足够余额
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        //检查是否溢出

        //保存数据用于后面的判断
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        //从发送者减掉发送额
        balanceOf[_to] += _value;
        //给接收者加上相同的量
        emit Transfer(_from, _to, _value);
        //通知任何监听该交易的客户端

        //判断买、卖双方的数据是否和转换前一致
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }


    /*公共函数
    * 从合约账户发送代币给外部账户（充值）
    * @param  _to address 接受代币的地址
    * @param  _value uint256 接受代币的数量
    */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
        //调用私有方法
    }

    /**
    * 从某个指定的帐户中，向另一个帐户发送代币(交易/打赏)
    *
    * 调用过程，会检查设置的允许最大交易额
    *
    * @param  _from address 发送者地址
    * @param  _to address 接受者地址
    * @param  _value uint256 要转移的代币数量
    * @return success        是否交易成功
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        // 检查发送者是否拥有足够余额
        allowance[_from][msg.sender] -= _value;
        //从发送者钱包中减去发送的代币
        _transfer(_from, _to, _value);
        // 调用私有方法
        return true;
        // 返回true
    }

    /**
     * 设置帐户允许支付的最大金额
     * @param _spender 帐户地址
     * @param _value 金额
    */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 设置帐户允许支付的最大金额
     *
     * 避免支付过多，造成风险，可以在 tokenRecipient 中做其他操作
     *
     * @param _spender 帐户地址
     * @param _value 金额
     * @param _extraData 发送给合约的附加数据
 */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        //调用外部合约接口，tokenRecipient里传入一个地址
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    /**
     * 减少合约账户的余额
     *
     * 操作以后是不可逆的
     *
     * @param _value 要删除的数量
     */
    function burn(uint256 _value) public returns (bool success) {
        //检查帐户余额是否大于要减去的值
        require(balanceOf[msg.sender] >= _value);
        //给指定帐户减去余额
        balanceOf[msg.sender] -= _value;
        //代币总数做相应扣除
        totalSupply -= _value;
        // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
    * 删除帐户的余额（含其他帐户）
    * @param _from 要操作的帐户地址
    * @param _value 要减去的数量
    */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}

