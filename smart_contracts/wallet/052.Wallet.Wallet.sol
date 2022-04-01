pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Wallet {
    uint256 balance = 0;
    address payable public owner;
    uint public commissionPersent = 5; // default commision persent
    address payable public commissionAdress = payable(0x617F2E2fD72FD9D5503197092aC168c91465E7f2); 
    // put here some address


    // tokens
    mapping(IERC20 => uint256) tokenBalance;
    mapping(address => mapping(IERC20 => uint256)) tokenAllowed;


    event ValueReceived(address user, uint256 amount);
    event TransferSent(address from, address to, uint256 amount);
    event Send(address user, uint amount);
    event TokenGet(IERC20 token, uint256 amount);
    event TokenAllovedGet(address ownerToken, uint256 amount);
    event AllowToken(address to, uint256 amount);
    event TransferSentAllowed(address ownerToken, address to, uint256 amount);


    constructor() payable {
        owner = payable(msg.sender);
        balance += msg.value;
    }
       
    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can do this');
        _;
    }

    // for eweryone to fulfil this wallet
    function send() external payable {
        balance += msg.value;
        emit ValueReceived(msg.sender, msg.value);
    }

    // withdraw all wei by owner
    function withdraw() external payable onlyOwner{
        uint amount = balance;
        owner.transfer(amount);
        balance = 0;
    }

    // trensfer money to someone
    function transfer(address payable to, uint amount) external onlyOwner {
        uint256 commission = amount * commissionPersent / 100;
        require(amount + commission <= balance, "balance is low");
        to.transfer(amount);
        commissionAdress.transfer(commission);
        balance -= amount + commission;
        emit Send(to, amount);
    }

    function balanceOf() external onlyOwner view returns(uint256) {
        return balance;
    }

    function setCommition(uint persent) public onlyOwner {
        commissionPersent = persent;
    }

    receive() external payable {
        balance += msg.value;
        emit ValueReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        balance += msg.value;
        emit ValueReceived(msg.sender, msg.value);
    }
    

    // token's part 
    function transferToken(IERC20 token, address to, uint256 amount) external onlyOwner payable {
        uint256 tokenNum = token.balanceOf(address(this));
        require(amount <=  tokenNum, "balance is low");
        token.transfer(to, amount);
        if (amount == tokenNum) {
            delete tokenBalance[token];
        }
        else {
            tokenBalance[token] -= amount;
        }
        emit TransferSent(msg.sender, to, amount);
    }  

    function getToken(IERC20 token) external onlyOwner {
        require(token.balanceOf(address(this)) > 0, 'You dont have any of this token');
        tokenBalance[token] = token.balanceOf(address(this));
        emit TokenGet(token, tokenBalance[token]);
    }

    function tokenBalanceOf(IERC20 token) external onlyOwner view returns(uint256) {
        require(token.balanceOf(address(this)) > 0, 'You dont have any of this token');
        return tokenBalance[token];
    }

    // allow spender some tokens to sell
    function allowToken(IERC20 token, address spender, uint256 amount) 
    external onlyOwner payable {
        uint256 tokenNum = token.balanceOf(address(this));
        require(amount <=  tokenNum, "balance is low");
        token.approve(spender, amount);
        emit AllowToken(spender, amount);
    }

    // get amount of token allowed for you to sell
    function getAllowedToken(IERC20 token, address ownerToken) external onlyOwner {
        uint256 tokenAllowedNum = token.allowance(ownerToken, address(this));
        require(tokenAllowedNum > 0, 'You dont have any of this token');
        tokenAllowed[ownerToken][token] = tokenAllowedNum;
        emit TokenAllovedGet(ownerToken, tokenAllowedNum);
    }


    function transferAllowedToken(IERC20 token, address ownerToken, address to, uint256 amount) 
    external onlyOwner payable {
        uint256 tokenAllowedNum = tokenAllowed[ownerToken][token];
        require(amount <=  tokenAllowedNum, "balance is low");
        token.transferFrom(address(this), to, amount);
        if (amount == tokenAllowedNum) {
            delete tokenAllowed[ownerToken][token];
        }
        else {
           tokenAllowed[ownerToken][token] -= amount;   
        }
        emit TransferSentAllowed(ownerToken, to, amount);
    }
    
}
