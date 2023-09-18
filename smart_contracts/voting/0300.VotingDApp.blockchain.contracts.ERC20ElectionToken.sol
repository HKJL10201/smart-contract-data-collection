// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


interface ERC20Interface {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


contract ERC20ElectionToken is ERC20Interface{
    string public constant name = "ERC20ElectionToken";
    string public constant symbol = "ERC20ET";
    uint8 public constant decimals = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 totalTokensSupply;
    address ERC20Owner;

    constructor (uint256 total) {
        totalTokensSupply = total;
        ERC20Owner = msg.sender;
        balances[ERC20Owner] = totalTokensSupply;
    }

    function totalSupply() public view override returns (uint256) {
        return totalTokensSupply;
    }

    function balanceOf(address account) public view override returns (uint) {
        return balances[account];
    }

    function transfer(address receiver, uint numTokens) public override returns (bool) {
        require(numTokens <= balances[ERC20Owner]);
        balances[ERC20Owner] = balances[ERC20Owner] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(ERC20Owner, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public override returns (bool) {
        require(msg.sender == ERC20Owner);
        allowed[ERC20Owner][delegate] = numTokens;
        emit Approval(ERC20Owner, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view override returns (uint) {
        require(owner == ERC20Owner);
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][ERC20Owner]);
        balances[owner] = balances[owner]-numTokens;
        allowed[owner][ERC20Owner] = allowed[owner][ERC20Owner]-numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}