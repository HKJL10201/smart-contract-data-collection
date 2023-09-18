// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CollectiveWallet {
    // The address of the contract owner
    address public owner;

    // The address of the token contract
    address public tokenAddress;

    // The number of approvals required for a transaction
    uint public requiredApprovals;

    // The total number of approvers
    uint public totalApprovers;

    // An array of addresses of the approvers
    address[] public approvers;

    // A mapping of transactions to the number of approvals they have received
    mapping(string => uint) public approvals;

    // A mapping of transactions to who approved
    mapping(string => address[]) public whoApproved;

    // A mapping of transactions to the recipient address
    mapping(string => address) public recipients;

    // A mapping of transactions to the amount of tokens that should be sent
    mapping(string => uint) public amounts;

    // An array of transactions that have been approved
    string[] public approvedTransactions;

    // The event that is emitted when a transaction is approved
    event TransactionApproved(string transactionId);


    function is_in(address[] memory arr, address val) private pure returns (bool) {
        for (uint j = 0; j < arr.length; j++) {
            if (arr[j] == val) {
                return true;
            }
        }
        return false;
    }


    function is_not_in(address[] memory arr, address val) private pure returns (bool) {
        for (uint j = 0; j < arr.length; j++) {
            if (arr[j] == val) {
                return false;
            }
        }
        return true;
    }


    constructor(address _tokenAddress, uint _requiredApprovals, uint _totalApprovers) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        requiredApprovals = _requiredApprovals;
        totalApprovers = _totalApprovers;
    }

    // Function to add an approver to the wallet
    function addApprover(address approver) public {
        // Only allow the wallet owner to add approvers
        require(msg.sender == owner, "Only the owner can add approvers");

        // Add the approver to the array of approvers
        approvers.push(approver);
    }

    // Function to submit a transaction for approval
    function submitTransaction(string calldata transactionId, address recipient, uint amount) public {

        require(is_in(approvers, msg.sender), "User is not an approver");

        // Get the ERC20 token contract
        IERC20 token = IERC20(tokenAddress);

        // Check that the sender has sufficient balance
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");

        // Add the transaction to the mapping of approvals
        approvals[transactionId] = 1; // To identify which does not exist and which is created.
        recipients[transactionId] = recipient;
        amounts[transactionId] = amount;
        whoApproved[transactionId].push(msg.sender);

        if (approvals[transactionId] >= requiredApprovals) {
            // Transfer the tokens to the recipient
            token.transfer(recipients[transactionId], amounts[transactionId]);

            // Add the transaction to the array of approved transactions
            approvedTransactions.push(transactionId);

            // Remove approvers to transaction that have already run.
            approvals[transactionId] = 0;

            // Emit the TransactionApproved event
            emit TransactionApproved(transactionId);
        }
    }

    // Function to approve a transaction
    function approveTransaction(string calldata transactionId) public {

        require(is_in(approvers, msg.sender), "User is not an approver");
        require(approvals[transactionId] != 0, "Transaction does not exist");
        require(is_not_in(whoApproved[transactionId], msg.sender), "User had already approved");

        // Increment the number of approvals for the transaction
        approvals[transactionId]++;
        whoApproved[transactionId].push(msg.sender);

        // Check if the transaction has received the required number of approvals
        if (approvals[transactionId] >= requiredApprovals) {
            // Get the ERC20 token contract
            IERC20 token = IERC20(tokenAddress);

            // Transfer the tokens to the recipient
            token.transfer(recipients[transactionId], amounts[transactionId]);

            // Add the transaction to the array of approved transactions
            approvedTransactions.push(transactionId);

            // Remove approvers to transaction that have already run.
            approvals[transactionId] = 0;

            // Emit the TransactionApproved event
            emit TransactionApproved(transactionId);
        }
    }
}
