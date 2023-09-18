//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC20Interface {

    function totalSupply() external view returns(uint256);
    
    function balanceOf(address account) external view returns(uint256);
    
    function allowance(address owner, address spender) external view returns(uint256);
    
    function transfer(address recipient, uint256 amount) external returns(bool);

    function transferToLottery(address customer, address recipient, uint256 amount) external returns(bool);
    
    function approve(address spender, uint256 amount) external returns(bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract ERC20 is ERC20Interface {
    
    string public constant name = "QuiniCoin";
    string public constant symbol = "QNI";
    uint8 public constant decimals = 2;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint256 totalSupply_;
    
    constructor(uint256 initialSupply) {
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
    }
    
    function totalSupply() public override view returns(uint256) {
        return totalSupply_;
    }
    
    function increaseTotalSupply(uint newTokensAmount) public {
        totalSupply_ += newTokensAmount;
        balances[msg.sender] += newTokensAmount;
    }
    
    function balanceOf(address tokenOwner) public override view returns(uint256) {
        return balances[tokenOwner];   
    }
    
    function allowance(address owner, address delegate) public override view returns(uint256) {
        return allowed[owner][delegate];
    }
    
    function transfer(address recipient, uint256 numTokens) public override returns(bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[recipient] += numTokens;
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    function transferToLottery(address customer, address recipient, uint256 numTokens) public override returns(bool) {
        require(numTokens <= balances[customer]);
        balances[customer] -= numTokens;
        balances[recipient] += numTokens;
        emit Transfer(customer, recipient, numTokens);
        return true;
    }
    
    function approve(address delegate, uint256 numTokens) public override returns(bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns(bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
}