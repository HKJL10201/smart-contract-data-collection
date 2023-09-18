// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./MultiOwnable.sol";
import "./Approvable.sol";

contract MultiSigWalletV2 is MultiOwnable, Approvable, PausableUpgradeable {

    // STATE VARIABLES
    address internal _walletCreator;

    struct TxRequest {
        address requestor;
        address recipient;
        string reason;
        uint amount;
        uint approvals;
        uint id;    // request id
    }
    
    TxRequest[] internal _txRequests;  // array's index == request id
    mapping (uint => address) internal _txRequestors;
    mapping (address => mapping (uint => bool)) internal _txApprovals;
        // approver => (requestId => approval?)
    
    uint _version;    //ADDED new state variable

    event DepositReceived(uint amount); 
    event TxRequestCreated(
        uint id,
        uint amount,
        address to,
        address requestor,
        string reason
    );
    event TxApprovalGiven(uint id, uint approvals, address lastApprover);
    event TransferSent(address to, uint amount); 

    // FUNCTIONS
    // Public & External functions
    
    function initialize(address[] memory owners, uint minTxApprovals)
        public
        virtual
        // override
        initializer
    {
        // MultiOwnable.initialize(owners);
        // Approvable.initialize(owners, minTxApprovals);
        MultiOwnable.initializeMultiOwnable(owners);
        Approvable.initializeApprovable(owners, minTxApprovals);
        PausableUpgradeable.__Pausable_init();

        _walletCreator = msg.sender;
        // _version = 13;  // Not executed as initializer only runs once i.e. upon INITIAL contract deploy
    }
    

    function deposit() external payable {
        require (msg.value > 0, "No funds sent to deposit!");
        emit DepositReceived(msg.value);
    }
    
        
    function createTransferRequest(
        address toAddress,
        string memory reason,
        uint amountWei
    )
        public
        onlyAnOwner
        returns (uint txId)
    {
        require(toAddress != address(0), "Recipient is address 0!");
        require(toAddress != address(this), "Recipeint is this wallet!");
        require(amountWei > 0, "Transfer amount is 0!");
        
        TxRequest memory newRequest =
            TxRequest(
                msg.sender,
                toAddress,
                reason,
                amountWei,
                0,
                _txRequests.length
            );

        _txRequests.push(newRequest);
        _txRequestors[newRequest.id] = msg.sender;
        
        emit TxRequestCreated(
            newRequest.id,
            newRequest.amount,
            newRequest.recipient,
            newRequest.requestor,
            newRequest.reason);

        return newRequest.id;
    }
    

    function approveTransferRequest(uint requestId)
        public
        onlyAnApprover
    {
        require(requestId < _txRequests.length, "No such request id!");
        require(_txRequests[requestId].amount > 0, "No transfer to approve!");
        require(
            _txApprovals[msg.sender][requestId] != true,
            "Already given approval!"
        );
        require(
            address(this).balance >= _txRequests[requestId].amount,
            "Insufficient funds for payment!"
        ); // NB.Gas cost not accounted for

        _txApprovals[msg.sender][requestId] = true;
        _txRequests[requestId].approvals++;
        
        emit TxApprovalGiven(requestId, _txRequests[requestId].approvals, msg.sender);
        
        if (_txRequests[requestId].approvals >= _minApprovals) {
            _makeApprovedTransfer(requestId);
        }
    }
    
    
    function cancelTransferRequest(uint requestId) public onlyAnOwner {
        require(requestId < _txRequests.length, "No such request id!");
        require(
            _txRequestors[requestId] == msg.sender,
            "Not transfer creator!"
        );
        _deleteTransferRequest(requestId);
    }
    

    // Internal and private functions
    
    function _deleteTransferRequest(uint requestId) internal {
        delete _txRequests[requestId];
        delete _txRequestors[requestId];
    }
    
    
    function _makeApprovedTransfer(uint requestId) internal {
        address sendTo = _txRequests[requestId].recipient;
        uint amountInWei = _txRequests[requestId].amount;
        _deleteTransferRequest(requestId);

        _transfer(sendTo, amountInWei);
            
        emit TransferSent(sendTo, amountInWei);
    }
            
    
    function _transfer(address sendTo, uint amountInWei) internal {
        // address payable to = address(uint160(sendTo));
        // to.transfer(amountInWei);
        payable(sendTo).transfer(amountInWei);
    }
    

    // Functions for Developer testing 

    function getTransferRequest(uint id)
        public
        view
        returns (TxRequest memory transferRequest)
    {
        return _txRequests[id];
    }
    
    function getWalletBalance() public view whenNotPaused returns (uint balance) {
        return address(this).balance;
    }
    
    function getWalletCreator() public view returns (address) {
        return _walletCreator;
    }
    
    function totalTransferRequests() public view returns (uint) {
        return _txRequests.length; // Includes cancelled & approved requests
    }

    function setWalletVersion(uint number) public onlyAnOwner {
        _version = number;
    }

    function getWalletVersion() public view returns (uint) {
        return _version;
    }

    function pause() public onlyAnOwner whenNotPaused {
      _pause();
    }

    function unpause() public onlyAnOwner whenPaused {
      _unpause();
    }

}