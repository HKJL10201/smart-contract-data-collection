pragma solidity ^0.8.0;

interface IERC20{
    // emitted when `value` tokens are transferred from one account to another
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    // returns total tokens
    function totalSupply() external view returns (uint);
    // returns tokens of person
    function balanceOf(address account) external view returns (uint);
    // transfers tokens of person to another
    function transfer(address to, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    // emits an approval event
    function approve(address spender, uint value) external returns (bool);
    // transfers tokens from one person to another, returns boolean value
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract ERC20 is IERC20{
    // total supplu
    uint private supply;
    // name of token
    string public name;
    // symbol of token
    string public symbol;
    // balances stored of each person
    mapping(address => uint256) public balance;
    // checking which address has been granted permission of approving
    mapping(address => mapping(address => uint)) public allowances;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        supply = _totalSupply;
        balance[msg.sender] = _totalSupply;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getSymbol() external view returns (string memory) {
		return symbol;
	}

    function getDecimals() external pure returns (uint) {
		return 18;
	}

	function totalSupply() external override view returns (uint) {
		return supply;
	}

    function balanceOf(address account) external override view returns (uint) {
		return balance[account];
	}

    // check allowance of a person
	function allowance(address owner, address spender) external override view returns (uint) {
		return allowances[owner][spender];
	}

	function approve(address spender, uint value) external override returns (bool) {
        // spender can't have address 0
        require(spender!=address(0));
		allowances[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

    function transfer(address to, uint value) public virtual override returns (bool) {
        // sender must have enough balance
        require(balance[msg.sender]>=value);
        balance[msg.sender] -= value;
        balance[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public virtual override returns (bool) {
        require(balance[from] >= value && allowances[from][msg.sender] >= value);
        allowances[from][msg.sender] -= value;
        balance[from] -= value;
        balance[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}

contract ZohairToken is ERC20{
    address public admin;
    address payable public deposit;
    uint public saleStart = block.timestamp;
    uint public saleEnd = saleStart+604800;
    uint public raisedAmount;
    uint public hardCap=  300 ether;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.01 ether;
    uint public tokenPrice=0.001 ether;
    uint public coinTradeStart = saleEnd + 7 days;
    
    enum state {preStart, running, end, stopped} state public icoState;
    
    modifier onlyAdmin{
        require(msg.sender==admin);
        _;
    }
    
    event Invest(address investor, uint value, uint tokens);
    
    constructor(address payable _deposit){
        admin = msg.sender;
        deposit = _deposit;
        icoState = state.preStart;
    }
    
    function stop() public onlyAdmin{
        icoState = state.stopped;
    }
    
    function unhalt() public onlyAdmin{
        icoState = state.running;
    }
    
    function changeDepositAddress(address payable _deposit) public onlyAdmin{
        deposit = _deposit;
    }
    
    function getCurrentState() public view returns(state){

        if(icoState==state.stopped){
            return state.stopped;
        }

        else if(block.timestamp < saleStart){
            return state.preStart;
        }

        else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return state.running;
        }
        
        else {
            return state.end;
        }
    }
    
    function invest() payable public returns(bool){

        icoState = getCurrentState();
        require(icoState == state.running && msg.value >= minInvestment && msg.value<=maxInvestment);

        uint tokens = msg.value/tokenPrice;
        require(raisedAmount+msg.value <= hardCap);

        raisedAmount += msg.value;
        balance[msg.sender] += tokens;
        balance[admin] -= tokens;
        deposit.transfer(msg.value);
        emit Invest(msg.sender, msg.value, tokens);
        return true;
    }

    function callInvest() external payable {
        invest();
    }
    
    function transfer(address to, uint tokens) public override returns (bool){
        require(block.timestamp > coinTradeStart);
        super.transfer(to, tokens);
    }
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool){
        require(block.timestamp > coinTradeStart);
        super.transferFrom(from, to, tokens);
    }
    
    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == state.end);
        balance[admin]=0;
    }
}

