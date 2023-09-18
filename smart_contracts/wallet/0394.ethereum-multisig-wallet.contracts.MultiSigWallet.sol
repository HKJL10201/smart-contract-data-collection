pragma solidity ^0.8.0;
pragma abicoder v2;

contract MultiSigWallet {

    // just an internal tracking for anyone who deposited
    mapping(address => uint) balance;

    address[] public owners;
    uint public requiredApprovals;

    // data structure for transfer request containing the address, amount to be sent, owners who approved the request, is the request processed (sent)
    struct TransferRequest {
        address payable recipient;
        uint amount;
        address[] approvers;
        bool sent;
        uint requestID;
    }

    // container for all transfer request
    TransferRequest[] transferRequests;

    constructor (address[] memory _owners, uint _requiredApprovals) {
        owners = _owners;
        requiredApprovals = _requiredApprovals;
    }

    modifier onlyOwner {
        require(isOwner(msg.sender), "You are not an owner to do this process.");
        _;
    }

    event depositFund(address sender, uint amount);
    event transferRequestMade(address creator, address recipient, uint amount);
    event approveRequest(address approver, uint requestId);
    event transferComplete(address recipient, uint amount, uint requestId);


    function deposit() public payable returns(uint) {
        balance[msg.sender] += msg.value;

        emit depositFund(msg.sender, msg.value);

        return balance[msg.sender];
    }

    function getDepositRecord() public view returns(uint) {
        return balance[msg.sender];
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getTransferRequest(uint _requestIndex) public view returns(TransferRequest memory) {
        return transferRequests[_requestIndex];
    }

    function getAllRequests() public view returns(TransferRequest[] memory) {
        return transferRequests;
    }

    function transfer(address payable _sentTo, uint _amount) public onlyOwner returns(uint) {
        require(getBalance() >= _amount, "Not enough funds.");

        // initialize empty array of address
        transferRequests.push(TransferRequest(_sentTo, _amount, new address[](0), false, transferRequests.length));

        emit transferRequestMade(msg.sender, _sentTo, _amount);

        return _amount;
    }

    function approveTransferRequest(uint _requestIndex) public onlyOwner returns(TransferRequest memory) {
        require(!transferRequests[_requestIndex].sent, "You cannot approve already sent transfer");
        require(!hasApproved(msg.sender, transferRequests[_requestIndex].approvers), "You already approved the transfer request.");

        transferRequests[_requestIndex].approvers.push(msg.sender);

        processTransferRequest(_requestIndex);

        emit approveRequest(msg.sender, _requestIndex);

        return transferRequests[_requestIndex];
    }

    function processTransferRequest(uint _requestIndex) private {
        if (transferRequests[_requestIndex].approvers.length == requiredApprovals) {
            // with the required approvals, transfer is sent
            transferRequests[_requestIndex].sent = true;
            transferRequests[_requestIndex].recipient.transfer(transferRequests[_requestIndex].amount);

            emit transferComplete(transferRequests[_requestIndex].recipient, transferRequests[_requestIndex].amount, _requestIndex);
        }
    }

    // helper function to check if an address is an owner
    function isOwner(address _address) private view returns(bool) {
        bool isAddressAnOwner = false;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                isAddressAnOwner = true;
            }
        }
        return isAddressAnOwner;
    }

    // helper function to check if an address (owner) has already approved the transfer request
    // which is more optimal (1) a view function, passing the index then accessing the state, or (2) a pure function, passing a copy of the approvers array
    function hasApproved(address _address, address[] memory _requestApprovers) private pure returns(bool) {
        bool approved = false;
        for (uint i = 0; i < _requestApprovers.length; i++) {
            if (_requestApprovers[i] == _address) {
                approved = true;
            }
        }
        return approved;
    }
    
}