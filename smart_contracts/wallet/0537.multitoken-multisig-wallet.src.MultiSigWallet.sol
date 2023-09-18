// SPDX-License-Identifier: MIT

/*

      .oooo.               oooooo     oooo           oooo                      o8o                       
     d8P'`Y8b               `888.     .8'            `888                      `"'                       
    888    888 oooo    ooo   `888.   .8'    .oooo.    888   .ooooo.  oooo d8b oooo  oooo  oooo   .oooo.o 
    888    888  `88b..8P'     `888. .8'    `P  )88b   888  d88' `88b `888""8P `888  `888  `888  d88(  "8 
    888    888    Y888'        `888.8'      .oP"888   888  888ooo888  888      888   888   888  `"Y88b.  
    `88b  d88'  .o8"'88b        `888'      d8(  888   888  888    .o  888      888   888   888  o.  )88b 
     `Y8bd8P'  o88'   888o       `8'       `Y888""8o o888o `Y8bod8P' d888b    o888o  `V88V"V8P' 8""888P' 

*/

pragma solidity 0.8.17;

/// @title MultiSigWallet
/// @author 0xValerius
/// @notice A multisignature wallet smart contract that can manage both ETH and ERC20 tokens.
contract MultiSigWallet {
    /// @notice Emitted when a deposit is received.
    /// @param sender The address of the sender.
    /// @param amount The amount of ether deposited.
    event Deposit(address indexed sender, uint256 amount);

    /// @notice Emitted when a new transaction is submitted.
    /// @param txId The ID of the submitted transaction.
    event Submit(uint256 indexed txId);

    /// @notice Emitted when an owner approves a transaction.
    /// @param owner The address of the approving owner.
    /// @param txId The ID of the approved transaction.
    event Approve(address indexed owner, uint256 indexed txId);

    /// @notice Emitted when an owner revokes approval for a transaction.
    /// @param owner The address of the revoking owner.
    /// @param txId The ID of the transaction for which approval is revoked.
    event Revoke(address indexed owner, uint256 indexed txId);

    /// @notice Emitted when a transaction is executed.
    /// @param txId The ID of the executed transaction.
    event Execute(uint256 indexed txId);

    struct Transaction {
        address proposer;
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public quorum;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    /// @notice Ensures that only wallet owners can call a function.
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner.");
        _;
    }

    /// @dev Initializes the multisig wallet with the provided owners and quorum.
    /// @param _owner The array of wallet owner addresses.
    /// @param _quorum The minimum number of approvals required to execute a transaction.
    constructor(address[] memory _owner, uint256 _quorum) {
        require(_owner.length > 0, "At least 1 owner required.");
        require(_quorum > 0 && _quorum <= _owner.length, "Invalid quorum.");

        for (uint256 i; i < _owner.length; i++) {
            address owner = _owner[i];
            require(owner != address(0), "Invalid owner.");
            require(isOwner[owner] == false, "Duplicate Owner.");

            isOwner[owner] = true;
            owners.push(owner);
        }
        quorum = _quorum;
    }

    /// @notice Allows deposits to the contract.
    /// @dev This function will be called when ether is sent to the contract.
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Submits a new transaction for approval.
    /// @param _to The recipient address.
    /// @param _value The amount of ether to send.
    /// @param _data The data payload of the transaction.
    function submitTransaction(address _to, uint256 _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({proposer: msg.sender, to: _to, value: _value, data: _data, executed: false}));
        isConfirmed[transactions.length - 1][msg.sender] = true;
        emit Submit(transactions.length - 1);
    }

    /// @notice Submits a new ERC20 token transaction for approval.
    /// @param _token The address of the ERC20 token contract.
    /// @param _to The recipient address.
    /// @param _value The amount of tokens to send.
    function submitTokenTransaction(address _token, address _to, uint256 _value) external onlyOwner {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", _to, _value);
        transactions.push(Transaction({proposer: msg.sender, to: _token, value: 0, data: data, executed: false}));
        isConfirmed[transactions.length - 1][msg.sender] = true;
        emit Submit(transactions.length - 1);
    }

    /// @notice Approves a transaction.
    /// @param _txId The ID of the transaction to approve.
    function approveTransaction(uint256 _txId) external onlyOwner {
        require(_txId < transactions.length, "Tx does not exist.");
        require(!transactions[_txId].executed, "Transaction already executed.");
        require(transactions[_txId].to != address(0), "Invalid transaction receiver.");
        require(!isConfirmed[_txId][msg.sender], "Transaction already approved.");
        isConfirmed[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    /// @notice Revokes an approval for a transaction.
    /// @param _txId The ID of the transaction for which to revoke approval.
    function revokeApproval(uint256 _txId) external onlyOwner {
        require(_txId < transactions.length, "Tx does not exist.");
        require(!transactions[_txId].executed, "Transaction already executed.");
        isConfirmed[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    /// @notice Gets the number of approvals for a transaction.
    /// @dev This is a private helper function.
    /// @param _txId The ID of the transaction to get the approval count for.
    /// @return count The number of approvals for the transaction.
    function _getApprovalCount(uint256 _txId) private view returns (uint256 count) {
        count = 0;
        for (uint256 i; i < owners.length; i++) {
            if (isConfirmed[_txId][owners[i]]) {
                count++;
            }
        }
    }

    /// @notice Executes a transaction if it has received enough approvals.
    /// @param _txId The ID of the transaction to execute.
    function executeTransaction(uint256 _txId) external onlyOwner {
        require(_txId < transactions.length, "Tx does not exist.");
        require(!transactions[_txId].executed, "Transction already executed.");
        require(_getApprovalCount(_txId) >= quorum, "Not enough approvals.");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success,) = transaction.to.call{value: transactions[_txId].value}(transaction.data);
        require(success, "Transaction failed.");
        emit Execute(_txId);
    }
}
