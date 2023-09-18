pragma solidity > 0.8.9;

contract VotingToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping (address => uint256) public depositOf;

    event Transfer(address _from, address _to, uint256 _value);
    event Approve(address, address, uint256);

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply){
        name = _name;
        symbol = _symbol;
        balanceOf[msg.sender] = _initialSupply;
        totalSupply += _initialSupply;
    }
    function deposit() payable public {
        depositOf[msg.sender] = msg.value;
        // 0.1 eth 1000token
        uint256 totalTokenReceive = msg.value * 1000 / (0.1 * 10**18);
        balanceOf[msg.sender] = totalTokenReceive;
        totalSupply += totalTokenReceive;
    }

    function transfer(address _to, uint256 _value) public returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balanceOf[_from] > _value, "Insufficient balance");
        require(_to != address(0), "Address 0 repipient");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
    }

    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance") ;
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}