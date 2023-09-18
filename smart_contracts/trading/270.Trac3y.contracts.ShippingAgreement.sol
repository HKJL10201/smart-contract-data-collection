// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ShippingAgreement is Ownable {
    enum shipping_states {
        SHIPPING,
        RECEIVED
    }

    shipping_states public state;

    // Requirements
    uint max_temp = 60; // Fahrenheit
    uint max_acc = 2;

    // Final values at receipt
    uint receipt_temp;
    uint receipt_acc;

    address public package_address;
    address payable public sender;
    address payable public shipper;
    address public recipient;

    uint reward_amount;
    address reward_token_address;
    uint fee_amount;
    uint penalty_amount = 0;

    constructor(
        address _shipper,
        address _recipient,
        address _reward_token_address,
        uint _reward_amount,
        address _package_address
    ) payable {
        sender = payable(msg.sender);
        shipper = payable(_shipper);
        recipient = _recipient;
        package_address = _package_address;

        reward_token_address = _reward_token_address;
        reward_amount = _reward_amount;

        // Deposit reward in smart contract

        require(
            IERC20(reward_token_address).transfer(address(this), reward_amount),
            "Depositing reward failed"
        );

        fee_amount = _reward_amount / 100;

        state = shipping_states.SHIPPING;
        // Deposit reward in smart contract
    }

    function receiveShipment(
        uint _temp,
        uint _acc,
        string calldata _signature
    ) public {
        require(msg.sender == recipient, "You are not the recipient"); // Only the recipient can receive the shipment

        // Check signature
        require(
            ECDSA.recover(
                keccak256(abi.encodePacked(_temp, _acc)),
                bytes(_signature)
            ) == package_address,
            "Invalid signature"
        );

        // For each requirement decrease reward and increase penalty
        // checking to see if read temp has exceeded the set max_temp, if so removing a percent of the reward as penalty
        if (_temp > max_temp) {
            uint penaltytemp = _temp - max_temp;
            penalty_amount += penaltytemp * (reward_amount / 100);
        }

        // checking to see if read acceleration has exceeded the set max_accel, if so removing a percent of the reward as penalty
        if (_acc > max_acc) {
            uint penaltyacc = _acc - max_acc;
            penalty_amount += penaltyacc * (reward_amount / 10);
        }

        if (penalty_amount >= (reward_amount - fee_amount)) {
            reward_amount = 0;
            penalty_amount = reward_amount - fee_amount;
        } else {
            reward_amount = reward_amount - fee_amount - penalty_amount;
        }

        receipt_temp = _temp;
        receipt_acc = _acc;

        state = shipping_states.RECEIVED;
    }

    function getDeliverySummary()
        public
        view
        returns (uint, uint, uint, uint, uint, uint, uint)
    {
        require(state == shipping_states.RECEIVED, "Shipment not received"); // Shipment must be received
        return (
            receipt_temp,
            max_temp,
            receipt_acc,
            max_acc,
            reward_amount,
            penalty_amount,
            fee_amount
        );
    }

    // The shipper can withdraw the reward when the shipment is received
    function withdraw_reward() public {
        require(msg.sender == shipper, "You are not the shipper"); // Only the shipper can withdraw the reward
        require(state == shipping_states.RECEIVED, "Shipment not received"); // Shipment must be received

        require(
            IERC20(reward_token_address).transfer(msg.sender, reward_amount),
            "Withdrawing fees failed"
        );
    }

    // The sender can withdraw the penalty if the shipper does not fulfill the requirements of the agreement
    function withdraw_penalty() public {
        require(msg.sender == sender, "You are not the sender"); // Only the sender can withdraw the penalty
        require(state == shipping_states.RECEIVED, "Shipment not received"); // Shipment must be received

        // TODO send penalty amount of reward token to sender
        require(
            IERC20(reward_token_address).transfer(msg.sender, penalty_amount),
            "Withdrawing fees failed"
        );
    }

    function withdraw_fees() public onlyOwner {
        require(state == shipping_states.RECEIVED, "Shipment not received"); // Shipment must be received
        require(
            IERC20(reward_token_address).transfer(msg.sender, fee_amount),
            "Withdrawing fees failed"
        );
    }

    function reset() public {
        reward_amount = 1000;
        penalty_amount = 0;
        receipt_temp = 0;
        receipt_acc = 0;
        state = shipping_states.SHIPPING;
    }
}
