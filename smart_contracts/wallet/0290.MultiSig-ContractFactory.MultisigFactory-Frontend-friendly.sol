// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex, uint indexed numOfCon);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
        address tokenAddr;
        uint timestamp;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        // balance += msg.value;
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function deposit()payable external {
        emit Deposit(msg.sender, msg.value ,address(this).balance);
    }

    // function withdrawERC20(address token, address recipient, uint256 amount) public onlyOwner {
    //     require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");
    //     IERC20(token).transfer(recipient, amount);
    // }

    function balanceOfERC20(address token) public view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function submitTransaction(
        address payable _to,
        uint _value,
        address _tokenAddress
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                executed: false,
                numConfirmations: 0,
                tokenAddr: _tokenAddress,
                timestamp: block.timestamp
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value);
    }

    function confirmTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex, transaction.numConfirmations);
        if(transaction.numConfirmations>= numConfirmationsRequired){
        executeTransaction(_txIndex);
        }
    }

    function executeTransaction(
        uint _txIndex
    ) private onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        if(transaction.tokenAddr == 0x0000000000000000000000000000000000000000){
        (bool success,) = transaction.to.call{value: transaction.value}("");
        require(success, "Transaction failed");
        transaction.executed = true;
        emit ExecuteTransaction(msg.sender, _txIndex);
        return ;
        }
        require(IERC20(transaction.tokenAddr).transfer(transaction.to, transaction.value), "ERC20 Token Transfer failed");

        transaction.executed = true;
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,
            bool executed,
            uint numConfirmations,
            address tokenAddr
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.executed,
            transaction.numConfirmations,
            transaction.tokenAddr
        );
    }

    function getListOfTransactions() public view returns (Transaction[] memory){
        return transactions;
    }

    function getLimitedListOfTransactions(uint offset, uint limit) public view returns ( Transaction[] memory) {
        uint length = transactions.length - offset;
        uint size = length < limit ? length : limit;
        uint x = offset;
        Transaction[] memory result = new Transaction[](size);
        for (uint i = 0; i < size; i++){
            result[i] = transactions[x];
            x++;
        }
        return result;
    }

    function getPendingTransaction () public view returns (Transaction[] memory){
        uint count = 0;
        for (uint i = 0; i < transactions.length; i++){
            if (!transactions[i].executed){
                count++;
            }
        }
        Transaction[] memory result = new Transaction[](count);
        count = 0;
        for (uint i = 0; i < transactions.length; i++){
            if (!transactions[i].executed){
                result[count] = transactions[i];
                count++;
            }
        }
        return result;
    }

    function getOffsetPendingTransaction (uint offset, uint limit) public view returns (Transaction[] memory){
         Transaction[] memory pendingTransactions = getPendingTransaction();
          uint length = pendingTransactions.length - offset;
          uint size = length < limit ? length : limit;
          uint x = offset;
          Transaction[] memory result = new Transaction[](size);
          for (uint i = 0; i < size; i++){
              result[i] = pendingTransactions[x];
              x++;
          }
          return result;
    }
}

contract multiSigContractFactory {

   struct NewDeployedContract {
        address creator;
        uint time;
        address[] newOwners;
        uint numReq;
    }
    uint public contractBalance;
    address public owner;

    mapping(address => NewDeployedContract) private registry;

    mapping(address => address[]) public ownersContracts;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

    function withdrawFunds(uint amount) public onlyOwner {
        require(amount <= contractBalance, "Insufficient funds in contract");
        payable(owner).transfer(amount);
        contractBalance -= amount;
    }

    function createContract(address[] memory _owners, uint _threshold) public payable returns (address) {
        require(msg.value >= 0.01 ether, "Sent value must be at least 0.01 ether");
        MultiSigWallet newMultisig = new MultiSigWallet(_owners, _threshold);
        for (uint i = 0; i < _owners.length; i++){
            ownersContracts[_owners[i]].push(address(newMultisig));
        }
        registry[address(newMultisig)] = NewDeployedContract({
                creator: msg.sender,
                time: block.timestamp,
                newOwners: _owners,
                numReq: _threshold
            });
        contractBalance += msg.value;
        return address(newMultisig);
    }

    //use New Multisig contract addr to get Owners and Threshold
    function getContractContents(address _index) public view returns (address, uint, address[] memory, uint) {
     NewDeployedContract storage contractInstance = registry[_index];
     return (contractInstance.creator, contractInstance.time, contractInstance.newOwners, contractInstance.numReq);
    }

    //use owner address and to retrieve array of contract address
     function getOwnersContract() public view returns (address[] memory) {
     return (ownersContracts[msg.sender]);
    }

}
