// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// EIP-20: ERC-20 Token Standard


interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract Cryptos is ERC20Interface{
    string public name = "ERC20 Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0; //18 is very common
    uint public override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances;
    // balances[0x1111...] = 100;
    
    mapping(address => mapping(address => uint)) allowed;
    // allowed[0x111][0x222] = 100;
    
    
    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender] >= tokens);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         balances[to] += tokens;
         allowed[from][to] -= tokens;
         
         return true;
     }
}

contract CryptosICO is Cryptos{
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether; // 1 eth = 1000 CPRT tokens
    uint public hardcap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; // want to end ICO in one week hence adding 1 week seconds
    uint public tokenTradeStart = saleEnd + 604800; //after one week of ICO ends
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;
    
    enum State {BeforeStart, Running, AfterEnd, Halted}
    
    State public icoState;
    
    constructor(address payable _deposit){
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.BeforeStart;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    function haltICO()public onlyAdmin {
        icoState = State.Halted;
    }
    
    function resumeICO() public onlyAdmin{
        icoState = State.Running;
    }
    
    function ChangeDepositAddress(address payable newDepositAddres) public onlyAdmin {
        deposit= newDepositAddres;
    }
    
    function getCurrentState() public view returns(State){
        if (icoState == State.Halted){
            return State.Halted;
        }
        else if(block.timestamp < saleStart){
            return State.BeforeStart;
        }
        else if(block.timestamp > saleStart && block.timestamp < saleEnd){
            return State.Running;
        }
        else{
            return State.AfterEnd;
        }
        
    }
    
    event Invest(address investor, uint value, uint tokens);
    
    function invest() payable public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.Running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        raisedAmount += msg.value;
        require(raisedAmount <= hardcap);
        
        uint tokens = msg.value / tokenPrice;
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
    } 
    
    receive() payable external{
        invest();
    }
    
    // allowing users to trade their tokens after trading block period i.e. tokenTradeStart
    //overriding sub contract's functions
    
    function transfer(address to, uint tokens) public override returns(bool success){
        require(block.timestamp > tokenTradeStart);
        Cryptos.transfer(to, tokens); // can also write as super.transfer(to, tokens)
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
        require(block.timestamp > tokenTradeStart);
        Cryptos.transferFrom(from, to, tokens);
        return true;
    }
    
    //burn the tokens, generally, any unused tokens can be hold by owner or just destroy them depends on the situation
    function burn() public onlyAdmin returns(bool){
        icoState = getCurrentState();
        require(icoState == State.AfterEnd);
        balances[founder] = 0; //just set to zero, remember the balance added to the founder at contract, i.e. only at the time of deployment and no other mehtod has this implementation
        return true;
    }
    
}