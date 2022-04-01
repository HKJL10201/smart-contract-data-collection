//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

interface IERC20 {

    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);

    function approve(address spender, uint tokens) external returns (bool success);

    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Cryptos is IERC20 {

    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0;
    uint public override totalSupply;
    address public founder;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;

    event Invest(address investor, uint value, uint tokens);

    constructor(){

        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance){

        return balances[tokenOwner];

    }

    function transfer(address to, uint tokens) public virtual override returns (bool success){

        require(balances[msg.sender] >= tokens);

        balances[to] += tokens;

        balances[msg.sender] -= tokens;

        emit Transfer(msg.sender, to, tokens);

        return true;


    }


    function allowance(address tokenOwner, address spender) view public override returns (uint){
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
        require(allowed[from][msg.sender] >= tokens);
        require(balances[from] >= tokens);

        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][msg.sender] -= tokens;

        return true;
    }

}

contract CryptosICO is Cryptos {

    //admin address
    address public admin;
    //address to which raisedAmount will be transferred to
    address payable public deposit;
    //1 CRPT = 0.001 ETH
    //price per token
    uint tokenPrice = 0.001 ether;
    //max tokens which can be sold
    uint public hardCap = 300 ether;
    uint public raisedAmount;
    //starting time of sale
    uint public saleStart = block.timestamp;
    //ico ends in 1 week
    //ending time of sale
    uint public saleEnd = block.timestamp + 604800;
    //token transfers after 1 week of sale end
    //starting time of transferring  tokens to owners
    uint public tokenTradeStart = saleEnd + 604800;
    //min amount which can be excepted to buy tokens
    uint public maxInvestment = 5 ether;
    //max amount which can ve excepted to buy tokens
    uint public minInvestment = 0.1 ether;

    //different states of ico
    enum State {beforeStart, running, afterEnd, halted}

    //track current state of ico
    State public icoState;


    constructor(address payable _deposit){

        //set the deposit address
        deposit = _deposit;
        //set the admin
        admin = msg.sender;
        //set the ico state
        icoState = State.beforeStart;
    }

    modifier onlyAdmin(){

        require(msg.sender == admin);
        _;
    }

    //change the ico state to halted
    function halt() public onlyAdmin {

        icoState = State.halted;

    }

    //change the ico state to running
    function resume() public onlyAdmin {

        icoState = State.running;
    }

    //change the deposit address
    function changeDepositAddress(address payable _newDeposit) public onlyAdmin {

        deposit = _newDeposit;
    }

    //get the current state of ico
    function getCurrentState() public view returns (State){

        if (icoState == State.halted) {

            return State.halted;
        }
        else if (block.timestamp < saleStart) {
            return State.beforeStart;
        }

        else if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {

            return State.running;
        }
        else {

            return State.afterEnd;
        }

    }

    //function to invest in ICO
    function invest() public payable returns (bool){

        icoState = getCurrentState();

        //check is ico is running
        require(icoState == State.running);

        //check for the amount invested
        require(msg.value >= minInvestment && msg.value <= maxInvestment);

        //increment the raised amount
        raisedAmount += msg.value;

        //check if raised amount is within the limit
        require(raisedAmount <= hardCap);

        //get the tokens to be sent to investor
        uint tokens = msg.value / tokenPrice;

        //send the tokens from token owner
        balances[msg.sender] += tokens;

        balances[founder] -= tokens;

        //send the amount to depositor
        deposit.transfer(msg.value);

        emit Invest(msg.sender, msg.value, tokens);

        return true;


    }

    receive() payable external {

        //this function will be automatically called if someone sends ether directly to contract address
        invest();
    }

    //transfer tokens to a address
    function transfer(address to, uint tokens) public override returns (bool success){

        require(block.timestamp > tokenTradeStart);
        super.transfer(to, tokens);

        return true;
    }

    //transfer tokens from token owner to another address via spender
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){

        require(block.timestamp > tokenTradeStart);

        super.transferFrom(from, to, tokens);

        return true;

    }


    //burn the remaining tokens after sale ends
    function burn() public returns (bool){

        icoState = getCurrentState();

        require(icoState == State.afterEnd);

        balances[founder] = 0;
        return true;
    }


}