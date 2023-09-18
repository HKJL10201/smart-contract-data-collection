// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Token {

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event NewMinter(address minter);
    event NewTimelock(address timelock);

    string public constant name = "Token";
    string public constant symbol = "TKN";
    uint public constant decimals = 18;

    uint public totalSupply;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    address public minter;
    address public timelock;

    constructor(uint _totalSupply, address _minter) {
        totalSupply = _totalSupply;
        minter = _minter;
        balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function approve(address spender, uint value) public returns (bool) {
        address sender = msg.sender;
        allowance[sender][spender] = value;
        emit Approval(sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) public returns (bool) {
        if (to == address(0))
            revert TransferToZeroAddress();
        address sender = msg.sender;
        uint senderBalance = balanceOf[sender];
        if (senderBalance < value)
            revert ValueExceedsBalance();
        balanceOf[sender] = senderBalance - value;
        balanceOf[to] += value;
        emit Transfer(sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        if (allowance[from][msg.sender] < value)
            revert ValueExceedsAllowance();
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint value) public onlyMinter {
        if (to == address(0))
            revert TransferToZeroAddress();
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function setMinter(address newMinter) public onlyTimelock {
        minter = newMinter;
        emit NewMinter(newMinter);
    }

    function setTimelock(address newTimelock) public onlyTimelock {
        timelock = newTimelock;
        emit NewTimelock(newTimelock);
    }

    /*
        Modifiers
    */
    modifier onlyMinter() {
        if (msg.sender != minter)
            revert MsgSenderIsNotMinter();
        _;
    }

    modifier onlyTimelock() {
        if (msg.sender != timelock)
            revert MsgSenderIsNotTimelock();
        _;
    }

    /*
        Custom Errors
    */
    error MsgSenderIsNotMinter();
    error MsgSenderIsNotTimelock();
    error TransferToZeroAddress();
    error ValueExceedsAllowance();
    error ValueExceedsBalance();
}
