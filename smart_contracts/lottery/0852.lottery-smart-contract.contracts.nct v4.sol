//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// The Cryptos Token Contract
contract Cryptos is ERC20Interface {
    string public name = "Nations Combat";
    string public symbol = "NCT";
    uint256 public decimals = 18;
    uint256 public override totalSupply;

    address public founder;
    mapping(address => uint256) public balances;
    // balances[0x1111...] = 100;

    mapping(address => mapping(address => uint256)) allowed;

    // allowed[0x111][0x222] = 100;

    constructor() {
        totalSupply = 50000000*10**18;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens)
        public
        virtual
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);

        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual override returns (bool success) {
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);

        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens;

        return true;
    }
}

contract CryptosICO is Cryptos {
    address public admin;
    address payable public deposit;
    uint256 tokenPrice = 0.001 ether; // 1 ETH = 1000 CRTP, 1 CRPT = 0.001
        uint256 public prie = 10;
  
    uint256 public raisedAmount; // this value will be in wei
    uint256 public saleStart = block.timestamp;
    uint256 public saleEnd = block.timestamp + 604800; //one week
    ERC20Interface public tokenContract;
    uint256 public tokenTradeStart = saleEnd + 604800; //transferable in a week after saleEnd
    uint256 public maxInvestment = 5 ether;
    uint256 public minInvestment = 0.001 ether;

    enum State {
        beforeStart,
        running,
        afterEnd,
        halted
    } // ICO states
    State public icoState;

    constructor(address payable _deposit, address tokenAddress) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
        tokenContract = ERC20Interface(tokenAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function resume() public onlyAdmin {
        icoState = State.running;
    }

    function changeDepositAddress(address payable newDeposit) public onlyAdmin {
        deposit = newDeposit;
    }

    function getCurrentState() public view returns (State) {
        if (icoState == State.halted) {
            return State.halted;
        } else if (block.timestamp < saleStart) {
            return State.beforeStart;
        } else if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }
function multiply(uint x, uint y) internal pure returns (uint z) {
require(y == 0 || (z = x * y) / y == x);
}
    event Invest(address investor, uint256 value, uint256 tokens);

function setPrice(uint256 _tokenPrice)public {
    tokenPrice = _tokenPrice; // 1 ETH = 1000 CRTP, 1 CRPT = 0.001

}
function getPrice(uint256 token) public view returns(uint256){
    return multiply(token, tokenPrice);
}
    // function called when sending eth to the contract
    function invest(uint256 token) public payable returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running ,"State is not running");
require(msg.value == multiply(token, tokenPrice),"eth sent is not enough");
        require(tokenContract.balanceOf(address(this))>= token*10**18,"No more token in the contract!");
        require(tokenContract.transfer(msg.sender, token*10**18));

        
        require(msg.value >= minInvestment && msg.value <= maxInvestment,"Max or Min investment Exceeded");

        raisedAmount += msg.value;

        // adding tokens to the inverstor's balance from the founder's balance
        balances[msg.sender] += token;
        balances[founder] -= token;
        deposit.transfer(msg.value); // transfering the value sent to the ICO to the deposit address

        emit Invest(msg.sender, msg.value, token);

        return true;
    }

    // this function is called automatically when someone sends ETH to the contract's address
    
  

    function transfer(address to, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(block.timestamp > tokenTradeStart); // the token will be transferable only after tokenTradeStart

        // calling the transfer function of the base contract
        super.transfer(to, tokens); // same as Cryptos.transfer(to, tokens);
        return true;
    }

    function endSale() public {
        require(msg.sender == admin);
        require(
            tokenContract.transfer(
                admin,
                tokenContract.balanceOf(address(this))
            )
        );

        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin
        payable(admin).transfer(address(this).balance);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart); // the token will be transferable only after tokenTradeStart

        Cryptos.transferFrom(from, to, tokens); // same as super.transferFrom(to, tokens);
        return true;
    }
}
