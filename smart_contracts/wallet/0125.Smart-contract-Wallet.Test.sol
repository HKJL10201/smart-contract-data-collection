pragma solidity >=0.7.0 <0.9.0;

contract MyContract {
    address public owner;
    address public constant adressHardCode = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    mapping (address => uint) public payments;

    string public constant name = "ERC20";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    uint256 totalSupply;

    constructor() {
        owner = msg.sender; //кто развернул контракт, тот и владелец
        balances[msg.sender] = totalSupply;
    }

    function pay() public payable {  // оплата eth
        payments[msg.sender] = msg.value;
        takeCommission(msg.sender, adressHardCode ,msg.value, 5);
    }

    function withdrawAll() public {  // владелец принимает со всех адресов eth
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function takeCommission(address _sender, address ownerAdress, uint256 _amountPaid, uint256 _commissionPercentage) private {
        // функция взымания комиссии в процентах
        require(_amountPaid % 100 == 0);
        uint256 comm = (_amountPaid  * _commissionPercentage) / 100;
        _amountPaid -= comm;
        payable(_sender).transfer(_amountPaid);
        payable(owner).transfer(comm);
    }

    function mint(address _to, uint _value) public { // эмиссия
        require(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
        balances[_to] += _value;
        totalSupply += _value;
    }

    function balanceOf(address _owner) public view returns(uint){ //проверка баланса
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns(uint){ //проверка баланса токенов
    return allowed[_owner][_spender];
    }

    function transfer(address _to, uint _value) public { // отправка токенов
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public{ // отправка с адреса
        require(balances[_from] >= _value && balances[_to] + _value >= balances[_to] && allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public{  // разрешение на снятие с указанного адреса
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
}
