//SPDX-License-Identifier: Open Source

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CGFMWallet: Crypto Gifts For Minors Wallet
/// @author Hico
/// @notice This contract has not been audited
/// @dev No side effects
contract Wallet is Ownable {
   
    address[] public approvers;
    uint public quorum;
    uint constant public MAX_APPROVER_COUNT = 10;

    address payable public beneficiary;
    uint public creationTime = block.timestamp; 
    bool public stopped = false; 

    struct Transfer {
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }
    Transfer[] public transfers; 
    mapping(address => mapping(uint => bool)) private approvals; 

    event EthReceived(address user, uint indexed amount);
    event WithdrawalRequested(uint indexed amount, address to);
    event WithdrawalApproved(uint indexed id);

    /// @notice Create Ownable MultiSig Timelock wallet with chosen approvers and amount of approvals needed for quorum
    /// @dev 
    /// @param _approvers addresses which are approvers of the Multi-Sig
    /// @param _quorum amount of approvers needed to send transfer
    /// @param _beneficiary only address which can request a 'send transfer' and 'close wallet' function.
    constructor(address[] memory _approvers, uint _quorum, address payable _beneficiary) validRequirement(_approvers.length, _quorum) {
        approvers = _approvers;
        quorum = _quorum;
        beneficiary = _beneficiary;
    }

    /// @notice Can send Eth to this wallet without any data
    /// @dev Receive function
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    /// @notice The function that is executed if not other fucntion matches the call
    /// @dev Fallback function
    fallback() external payable {}
    
    /// @notice Get the address list of approvers
    /// @dev
    /// @return Addresses of approvers
    function getApprovers() external view returns(address[] memory) {
        return approvers;
    }
    
    /// @notice Get the list and details of transfers 
    /// @dev
    /// @return Transfers list
    function getTransfers() external view returns(Transfer[] memory) {
        return transfers;
    }
    
    /// @notice When the contract turns 16, only beneficiary may request to withdraw Eth
    /// @dev 
    /// @param amount is the amount of Eth the beneficiary wants to withdraw
    /// @param to is the address that the beneficiary wants to send Eth to
    function createTransfer(uint amount, address payable to) external onlyBeneficiary() stopInEmergency() timeLock16() {
        require(address(this).balance > 0, 'There is zero Ether in this wallet');
        emit WithdrawalRequested(amount, to);
        transfers.push(Transfer(
            transfers.length,
            amount,
            to,
            0,
            false
        ));
    }
    
    /// @notice Approvers can approve a transfer request
    /// @dev
    /// @param id is the indexed transaction id number
    function approveTransfer(uint id) public onlyApprover() stopInEmergency() timeLock16() { 
        require(transfers[id].sent == false, 'Transfer has already been sent');
        require(approvals[msg.sender][id] == false, 'Cannot approve transfer for the second time');
        emit WithdrawalApproved(id);
        
        approvals[msg.sender][id] = true;
        transfers[id].approvals++;
        
        if(transfers[id].approvals >= quorum) {
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;
            to.transfer(amount); 
        }
    }
    
    /// @notice View balance of this contract
    /// @dev
    /// @return Balance of this contract 
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    /// @notice Toggle contract active by limiting certain functions
    /// @dev Circuit breaker 
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }

    /// @notice Beneficiary can choose to withdraw all Eth and close this contract
    /// @dev Selfdestruct function
    /// @return Balance of this address 
    function closeWallet() public onlyBeneficiary() timeLock18() returns(uint) {
        selfdestruct(beneficiary);
        return(address(this).balance);
    }

    modifier validRequirement(uint approverCount, uint _quorom) {
        require(approverCount <= MAX_APPROVER_COUNT
            && _quorom <= approverCount
            && _quorom != 0
            && approverCount != 0);
        _;
    }
    
    modifier onlyApprover() {
        bool allowed = false;
        for(uint i = 0; i < approvers.length; i++) {
            if(approvers[i] == msg.sender) {
                allowed = true;
            }
        }
        require(allowed == true, 'Valid approvers only.');
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "You are not the Beneficiary of this contract!");
        _; 
    }

    modifier timeLock16() {
        require(block.timestamp > (creationTime + 835 weeks), 'Beneficiary is not 16 years old.');
        _;
    }
      
    modifier timeLock18() {
        require(block.timestamp > (creationTime + 939 weeks), 'Beneficiary is not 18 years old.');
        _;
    }

    modifier stopInEmergency() { 
        require(!stopped, 'This contract is currently stopped'); 
        _; 
    }
}
