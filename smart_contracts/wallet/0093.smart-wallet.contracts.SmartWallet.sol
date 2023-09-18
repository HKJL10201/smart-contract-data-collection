//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
    @title  SmartWallet
    @author George Hervey
    @notice A simplistic smart contract wallet owned by the user for holding funds (ERC20 tokens and native cryptocurrency)
            and manage recurring payments. The SmartWallet allows users to set up automatic recurring payments
            that pre-approves receivers (e.g. subscription services) to pull tokens from it without need of involvement 
            from the user, similar to recurring payments with credit cards with additional securities. The user 
            needs to approve the payment terms upfront to start the recurring payments. On each payment, the receiver
            cannot transfer more tokens than the term amount and cannot transfer prior to the expiration date of the timelock,
            which resets on every recurring payment transaction to the next payment period.
 */
contract SmartWallet is Ownable {

    /*
    ===========================
        ***** EVENTS *****
    ===========================
    */

    event SubscriptionRequested(
        address to,
        address requestedBy,
        address receiver,
        uint256 amount,
        address token,
        uint256 interval,
        uint256 timestamp
    );
    
    event SubscriptionApproved(
        address approvedBy,
        address receiver,
        uint256 amount,
        address token,
        uint256 interval,
        uint256 timestamp
    );

    event SubscriptionRemoved(
        address removedBy,
        address receiver,
        uint256 amount,
        address token,
        uint256 interval,
        uint256 timestamp
    );

    event SubscriptionPaid(
        address from,
        address receiver,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    event InstallmentRequested(
        address to,
        address requestedBy,
        address receiver,
        uint256 amount,
        address token,
        uint256 interval,
        uint256 numberOfPayments,
        uint256 timestamp
    );

    event InstallmentApproved(
        address approvedBy,
        address receiver,
        uint256 amount,
        address token,
        uint256 interval,
        uint256 numberOfPayments,
        uint256 timestamp
    );

    event InstallmentPaid(
        address from,
        address receiver,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    event InstallmentFinished(
        address from,
        address receiver,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    struct Subscription {
        address receiver;
        uint256 amount;
        address token;
        uint256 interval; // monthly, annually (calculate by days)
        uint256 timelock;
    }

    struct Installment {
        address receiver;
        uint256 amount;
        address token;
        uint256 interval; // monthly, annually (calculate by days)
        uint256 timelock;
        uint256 remainingCount; // Number of installments left to pay before completing this term
    }

    /*
    =============================
        ***** VARIABLES *****
    =============================
    */

    address[] internal _receivers;
    mapping(address => Subscription) internal _subscriptions;
    mapping(address => Installment) internal _installments;
    mapping(address => bool) internal _approved;

    Subscription[] internal _subscriptionRequests;
    Installment[] internal _installmentRequests;

    /*
    ============================
        ***** MODIFIERS *****
    ============================
    */
    
    modifier onlyApproved(address receiver_) {
        require(_approved[receiver_], "Smart Wallet: Receiver is not approved.");
        _;
    }

    /*
    =============================
        ***** FUNCTIONS *****
    =============================
    */

    constructor(address owner_) {
        transferOwnership(owner_);
    }

    function requestSubscription(
        address receiver_,
        uint256 amount_,
        address token_,
        uint256 interval_,
        uint256 startDate_
    ) external {
        Subscription memory newTerms = Subscription(
            receiver_, 
            amount_, 
            token_,
            interval_,
            startDate_
        );
        
        _subscriptionRequests.push(newTerms);
        emit SubscriptionRequested(address(this), msg.sender, receiver_, amount_, token_, interval_, block.timestamp);
    }

    function requestInstallment(
        address receiver_,
        uint256 amount_,
        address token_,
        uint256 interval_,
        uint256 startDate_,
        uint256 count_
    ) external {
        Installment memory newTerms = Installment(
            receiver_, 
            amount_, 
            token_,
            interval_,
            startDate_,
            count_
        );
        
        _installmentRequests.push(newTerms);
        emit InstallmentRequested(address(this), msg.sender, receiver_, amount_, token_, interval_, count_, block.timestamp);
    }

    function getPendingSubscriptionRequests() external view returns (Subscription[] memory) {
        return _subscriptionRequests;
    }

    function getPendingInstallmentRequests() external view returns (Installment[] memory) {
        return _installmentRequests;
    }

    function getPendingSubscriptionRequestAtIndex(uint256 index_) external view returns (Subscription memory) {
        return _subscriptionRequests[index_];
    }

    function getPendingInstallmentRequestAtIndex(uint256 index_) external view returns (Installment memory) {
        return _installmentRequests[index_];
    }

    // Refactor to avoid ever-expanding unbounded array and remove empty indexes
    function approveSubscription(uint256 index_) external onlyOwner returns (bool) {
        Subscription memory pendingTerms = _subscriptionRequests[index_];
        _subscriptions[pendingTerms.receiver] = pendingTerms;
        _receivers.push(pendingTerms.receiver);
        _approved[pendingTerms.receiver] = true;
        emit SubscriptionApproved(msg.sender, pendingTerms.receiver, pendingTerms.amount, pendingTerms.token, pendingTerms.interval, block.timestamp);

        delete _subscriptionRequests[index_];
        return true;
    }

    // Refactor to avoid ever-expanding unbounded array and remove empty indexes
    function approveInstallment(uint256 index_) external onlyOwner returns (bool) {
        Installment memory pendingTerms = _installmentRequests[index_];
        _installments[pendingTerms.receiver] = pendingTerms;
        _receivers.push(pendingTerms.receiver);
        _approved[pendingTerms.receiver] = true;
        emit InstallmentApproved(msg.sender, pendingTerms.receiver, pendingTerms.amount, pendingTerms.token, pendingTerms.interval, pendingTerms.remainingCount, block.timestamp);

        delete _installmentRequests[index_];
        return true;
    }

    function collectFromInstallment(address receiver_, uint256 amount_) external onlyApproved(receiver_) {
        Installment memory terms = _installments[receiver_];
        require(terms.remainingCount >= 1, "Smart Wallet: No more installments are due");
        require(amount_ <= terms.amount, "Smart Wallet: Amount is greater than agreed terms");
        require(IERC20(terms.token).balanceOf(address(this)) >= amount_, "Smart Wallet: Balance is too low");
        require(block.timestamp >= terms.timelock, "Smart Wallet: Timelock has not expired yet.");

        IERC20(terms.token).transfer(receiver_, amount_);
        emit InstallmentPaid(address(this), receiver_, terms.token, terms.amount, block.timestamp);

        terms.timelock = block.timestamp + terms.interval;
        terms.remainingCount--;
        if (terms.remainingCount == 0) {
            delete _installments[receiver_];
        } else {
            _installments[receiver_] = terms;
        }
    }

    function collectFromSubscription(address receiver_, uint256 amount_) external onlyApproved(receiver_) {
        Subscription memory terms = _subscriptions[receiver_];
        require(amount_ <= terms.amount, "Smart Wallet: Amount is greater than agreed terms");
        require(IERC20(terms.token).balanceOf(address(this)) >= amount_, "Smart Wallet: Balance is too low");
        require(block.timestamp >= terms.timelock, "Smart Wallet: Timelock has not expired yet.");

        IERC20(terms.token).transfer(receiver_, amount_);
        emit SubscriptionPaid(address(this), receiver_, terms.token, amount_, block.timestamp);

        terms.timelock = block.timestamp + terms.interval;
        _subscriptions[receiver_] = terms;
    }

    function deleteSubscription(address receiver_) external onlyOwner {
        for (uint i=0; _receivers.length > i; i++) {
            if (_receivers[i] == receiver_) {
                Subscription memory terms = _subscriptions[receiver_];
                delete _receivers[i];
                delete _subscriptions[receiver_];
                _approved[receiver_] = false;
                emit SubscriptionRemoved(msg.sender, receiver_, terms.amount, terms.token, terms.interval, block.timestamp);
                break;
            }
        }
    }

    function withdraw(address token_, uint256 amount_) external onlyOwner {
        IERC20(token_).transferFrom(address(this), msg.sender, amount_);
    }

    function withdraw(uint256 amount_) external payable onlyOwner {
        payable(address(this)).transfer(amount_);
    }

    receive() external payable {}
}