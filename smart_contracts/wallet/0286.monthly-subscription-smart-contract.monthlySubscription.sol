// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MonthlySubscription is Ownable {
    using Counters for Counters.Counter;

    IERC20 public token; // The token used for subscription payments
    uint256 public subscriptionAmount; // Monthly subscription amount in token units
    uint256 public paymentDay; // Day of the month when the payment is due (1 to 28)

    mapping(address => uint256) public nextPaymentDates;
    Counters.Counter private subscriptionIds;

    event SubscriptionCreated(uint256 subscriptionId, address subscriber);
    event SubscriptionRenewed(uint256 subscriptionId, address subscriber, uint256 nextPaymentDate);
    event SubscriptionCancelled(uint256 subscriptionId, address subscriber);

    constructor(
        address _tokenAddress,
        uint256 _subscriptionAmount,
        uint256 _paymentDay
    ) {
        token = IERC20(_tokenAddress);
        subscriptionAmount = _subscriptionAmount;
        paymentDay = _paymentDay;
    }

    function createSubscription() external {
        require(nextPaymentDates[msg.sender] == 0, "Subscription already exists");
        subscriptionIds.increment();
        uint256 subscriptionId = subscriptionIds.current();
        nextPaymentDates[msg.sender] = block.timestamp + 30 days; // Start after 30 days from creation

        emit SubscriptionCreated(subscriptionId, msg.sender);
    }

    function renewSubscription() external {
        require(nextPaymentDates[msg.sender] != 0, "No subscription found");
        require(block.timestamp >= nextPaymentDates[msg.sender], "Payment not yet due");

        uint256 subscriptionId = getCurrentSubscriptionId(msg.sender);
        nextPaymentDates[msg.sender] += 30 days; // Renew for the next 30 days

        emit SubscriptionRenewed(subscriptionId, msg.sender, nextPaymentDates[msg.sender]);
    }

    function cancelSubscription() external {
        require(nextPaymentDates[msg.sender] != 0, "No subscription found");

        uint256 subscriptionId = getCurrentSubscriptionId(msg.sender);
        delete nextPaymentDates[msg.sender];

        emit SubscriptionCancelled(subscriptionId, msg.sender);
    }

    function getCurrentSubscriptionId(address subscriber) public view returns (uint256) {
        require(nextPaymentDates[subscriber] != 0, "No subscription found");

        // Use a formula to determine the subscription ID based on the subscriber's address and the contract address
        return uint256(keccak256(abi.encodePacked(subscriber, address(this))));
    }

    // Function to trigger the automatic deduction from Metamask wallet
    function deductSubscription() external {
        require(nextPaymentDates[msg.sender] != 0, "No subscription found");
        require(block.timestamp >= nextPaymentDates[msg.sender], "Payment not yet due");

        uint256 subscriptionId = getCurrentSubscriptionId(msg.sender);
        require(token.balanceOf(msg.sender) >= subscriptionAmount, "Insufficient balance");

        // Transfer the subscriptionAmount from the subscriber's wallet to the contract
        token.transferFrom(msg.sender, address(this), subscriptionAmount);

        nextPaymentDates[msg.sender] += 30 days; // Renew for the next 30 days

        emit SubscriptionRenewed(subscriptionId, msg.sender, nextPaymentDates[msg.sender]);
    }

    // Function to withdraw collected subscription funds (only for the contract owner)
    function withdrawFunds() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");

        token.transfer(owner(), balance);
    }
}
