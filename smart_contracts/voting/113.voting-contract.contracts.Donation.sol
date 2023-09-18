// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationContract {
    address public owner;
    address public beneficiary;
    bool public emergencyPaused;

    struct Donation {
        address donor;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    Donation[] public donations;
    mapping(address => bool) public donors;

    event DonationReceived(address indexed donor, uint256 amount, string message);
    event Withdrawal(address indexed beneficiary, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier notPaused() {
        require(!emergencyPaused, "Contract operations are paused");
        _;
    }

    constructor(address _beneficiary) {
        owner = msg.sender;
        beneficiary = _beneficiary;
    }

    function donate(string memory _message) external payable notPaused {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            message: _message,
            timestamp: block.timestamp
        }));
        
        if (!donors[msg.sender]) {
            donors[msg.sender] = true;
        }
        
        emit DonationReceived(msg.sender, msg.value, _message);
    }

    function getTotalDonations() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            total += donations[i].amount;
        }
        return total;
    }

    function getDonorList() external view returns (address[] memory) {
        address[] memory donorList = new address[](donations.length);
        for (uint256 i = 0; i < donations.length; i++) {
            donorList[i] = donations[i].donor;
        }
        return donorList;
    }

    function setBeneficiary(address _newBeneficiary) external onlyOwner {
        beneficiary = _newBeneficiary;
    }

    function emergencyPause(bool _paused) external onlyOwner {
        emergencyPaused = _paused;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Sorry! No funds available for withdrawal");
        uint256 balance = address(this).balance;
        (bool success, ) = beneficiary.call{value: balance}("");
        require(success, "Withdrawal failed!");
        emit Withdrawal(beneficiary, balance);
    }
}
