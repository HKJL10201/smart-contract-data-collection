pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

contract CryptoWallet {
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    
    address public owner;
    uint256 public withdrawalLimit;
    uint256 public lastWithdrawalTimestamp;
    uint256 public feePercentage;
    IERC20 public token;
    
    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(address _token, uint256 _withdrawalLimit, uint256 _feePercentage) payable {
        owner = msg.sender;
        withdrawalLimit = _withdrawalLimit;
        lastWithdrawalTimestamp = block.timestamp;
        feePercentage = _feePercentage;
        token = IERC20(_token);
        // Add starting balance of 100 ether
        balances[msg.sender] = 100 ether;
    }
    
    function deposit(uint256 _amount) public {
        require(_amount > 0, "Invalid amount");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        balances[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }
    
    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Invalid amount");
        require(_amount <= balances[msg.sender], "Insufficient balance");
        require(block.timestamp >= lastWithdrawalTimestamp + withdrawalLimit, "Withdrawal limit exceeded");
        
        uint256 fee = (_amount * feePercentage) / 100;
        uint256 amountAfterFee = _amount - fee;
        
        require(token.balanceOf(address(this)) >= amountAfterFee, "Insufficient balance in contract");
        
        balances[msg.sender] -= _amount;
        lastWithdrawalTimestamp = block.timestamp;
        
        require(token.transfer(msg.sender, amountAfterFee), "Transfer failed");
        
        emit Withdraw(msg.sender, _amount);
    }
    
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    function transfer(address _to, uint256 _amount) public {
        require(_amount > 0, "Invalid amount");
        require(_amount <= balances[msg.sender], "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        
        emit Transfer(msg.sender, _to, _amount);
    }
    
    function approve(address _spender, uint256 _amount) public payable {
        allowed[msg.sender][_spender] = _amount;
        require(token.approve(_spender, _amount), "Approval failed");
        emit Approval(msg.sender, _spender, _amount);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public {
        require(_amount <= allowed[_from][msg.sender], "Not allowed to spend this amount");
        require(_amount <= balances[_from], "Insufficient balance");
        
        balances[_from] -= _amount;
        balances[_to] += _amount;
        allowed[_from][msg.sender] -= _amount;
    
    emit Transfer(_from, _to, _amount);
    }

    function setWithdrawalLimit(uint256 _newWithdrawalLimit) public {
        require(msg.sender == owner, "Only owner can call this function");
        withdrawalLimit = _newWithdrawalLimit;
    }

    function setFeePercentage(uint256 _newFeePercentage) public {
        require(msg.sender == owner, "Only owner can call this function");
        feePercentage = _newFeePercentage;
    }

    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner, "Only owner can call this function");
        owner = _newOwner;
    }
}
