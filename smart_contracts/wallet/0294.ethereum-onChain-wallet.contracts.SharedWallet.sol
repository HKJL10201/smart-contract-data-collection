// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SharedWallet {
    event CreateAccount(address indexed sender);
    event AddUser(address indexed user, address indexed holder);
    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, address indexed to, uint256 amount);

    address public owner;
    uint256 public walletBalance;

    address[] public allAccountHolders;
    mapping(address => bool) public hasAccount;
    mapping(address => uint256) public accountBalance;

    struct User {
        address user_addr;
        address account_addr;
    }
    mapping(address => bool) public isUser;
    mapping(address => User) public users;

    constructor() {
        owner = msg.sender;
    }

    // function modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner.");
        _;
    }

    modifier onlyAccountHolder() {
        require(hasAccount[msg.sender], "Not an account holder");
        _;
    }

    modifier onlyNonAccountHolder() {
        require(hasAccount[msg.sender] == false, "Already has an account");
        _;
    }

    modifier onlyUser() {
        require(isUser[msg.sender], "Not a user");
        _;
    }

    function createAccount() public onlyNonAccountHolder {
        require(
            isUser[msg.sender] == false,
            "Already associated with an account"
        );

        allAccountHolders.push(msg.sender);
        hasAccount[msg.sender] = true;

        isUser[msg.sender] = true;

        users[msg.sender].user_addr = msg.sender;
        users[msg.sender].account_addr = msg.sender;

        emit CreateAccount(msg.sender);
    }

    function addUser(address _user) public onlyAccountHolder {
        require(_user != address(0), "Not a valid address");
        require(isUser[_user] == false, "Already associated with an account");

        isUser[_user] = true;

        users[_user].user_addr = _user;
        users[_user].account_addr = msg.sender;

        emit AddUser(_user, msg.sender);
    }

    function deposit() public payable onlyUser {
        require(msg.value != 0, "You need to deposit some amount of money");

        accountBalance[users[msg.sender].account_addr] += msg.value;
        walletBalance += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address payable _to, uint256 _amount) public onlyUser {
        require(_to != address(0), "Not a valid address");
        require(
            _amount <= accountBalance[users[msg.sender].account_addr],
            "You have insufficient balance to withdraw"
        );

        accountBalance[users[msg.sender].account_addr] -= _amount;
        walletBalance -= _amount;

        _to.transfer(_amount);

        emit Withdraw(msg.sender, _to, _amount);
    }

    // get account balance
    function getBalance() public view onlyUser returns (uint256) {
        return accountBalance[users[msg.sender].account_addr];
    }

    // Total Funds under Management in the Wallet
    function getTotalWalletBalance() public view onlyOwner returns (uint256) {
        return walletBalance;
    }

    function getAllAccountHolders()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        return allAccountHolders;
    }

    function getAccountNumber() public view onlyUser returns (address) {
        return users[msg.sender].account_addr;
    }
}
