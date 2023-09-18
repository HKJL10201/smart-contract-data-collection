//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
 
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
    string public name = "Cryptos";
    string public symbol = "CRPT"; // 4 characters
    uint public decimals = 0;// range from 0 to 18, 18 is the most used
    
    uint public override totalSupply; // it create the function
    
    address public founder;
    mapping(address => uint) public balances;
    // balances[0x11...] = 100;
    
    mapping(address => mapping(address => uint)) allowed;
    // [addr_own][addr_B] = 0, then allow 100: [addr_own][addr_B] = 100 
    
    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public virtual override returns (bool success){
        require(balances[msg.sender] >= tokens, "sender has not enough tokens");
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public override returns(bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns(bool success){
        require(allowed[from][to] >= tokens, "cannot allowed to because not enough tokens");
        require(balances[from] >= tokens, "cannot: balance is < tokens");
        
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens;
        
        return true;
    }
}


contract CryptosICO is Cryptos{
    address public admin;
    address payable public deposit;
    uint public tokenPrice = 0.001 ether;
    uint public hardCap = 300 ether;
    uint public raisedAmount; // in wei, by default
    uint public saleStart = block.timestamp; //start right now
    uint public saleEnd = saleStart + 604800; // 1 week
    uint public tokenTradeStart = saleEnd + 604800;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;
    
    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;
    
    constructor(address payable _deposit){
        deposit = _deposit; // vlaue can be hardcoded
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin, "Only the admin can do this call");
        _;
    }
    
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    function resume() public onlyAdmin{
        icoState = State.running;
    }
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    function getCurrentState() public view returns(State){
        if (icoState == State.halted){
            return State.halted;
        }else if (block.timestamp < saleStart){
            return State.beforeStart;
        }else if (block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }
    
    event Invest(address investor, uint value, uint tokens);
    
    function invest() payable public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.running, "invalid State !!");
        uint amount = msg.value;
        require(amount >= minInvestment && amount <= maxInvestment, "value invested not authorized !!");
        raisedAmount += amount;
        require(raisedAmount <= hardCap, "above the hardCap !!");
        
        uint tokens = amount /tokenPrice;
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        emit Invest(msg.sender, amount, tokens);
        deposit.transfer(amount);
        
        return true;
    }
    
    receive() payable external{
        invest();// automatically call when somebody send money to the contact
    }
    
    // current version kept for the "super" method. But why not just add a modifier onlyAfterTradeStarted ... ?
    //i.e: modifier onlyAfterTradeStarted(){require(block.timestamp > tokenTradeStart, "not yet tokenTradeStart !");}
    function transfer(address to, uint tokens) public override returns (bool success){
        require(block.timestamp > tokenTradeStart, "not yet tokenTradeStart !");
        Cryptos.transfer(to, tokens); //same as super.transfer(to, tokens); 
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public override returns(bool success){
        require(block.timestamp > tokenTradeStart, "not yet tokenTradeStart !");
        Cryptos.transferFrom(from, to, tokens);
        return true;
    }
    
    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }
}
