pragma solidity 0.7.5;
pragma abicoder v2;

contract MultiSigWallet {
    address public contractCreator;
    mapping (address => bool) public owners;
    uint public requiredApprovals;

    uint public balance;

    struct TransferRequest {
       uint requestId;
       address to;
       uint amount;
       mapping (address => bool) approvals;
       uint numApprovals;
    }

    mapping (uint => TransferRequest) transferRequests;
    uint numTransferRequests;

    modifier onlyOwners {
        require(owners[msg.sender]);
        _;
    }

    // ✅ The contract creator should be able to input (1): the addresses of the owners and (2):  the numbers of approvals required for a transfer, in the constructor. For example, input 3 addresses and set the approval limit to 2. 
    constructor(address[] memory _owners, uint _requiredApprovals) {
        contractCreator = msg.sender;

        for (uint i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = true;
        }
        requiredApprovals = _requiredApprovals;
    }

    // ✅ Anyone should be able to deposit ether into the smart contract
    function deposit() public payable returns (uint) {
        balance += msg.value;

        return balance;
    }

    function getSmartContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // ✅ Anyone of the owners should be able to create a transfer request. The creator of the transfer request will specify what amount and to what address the transfer will be made.
    function createTransferRequest(address _to, uint _amount) public onlyOwners returns (uint) {
        uint currentRequestIndex = numTransferRequests;

        TransferRequest storage transferRequest = transferRequests[numTransferRequests++];

        transferRequest.requestId = currentRequestIndex;
        transferRequest.to = _to;
        transferRequest.amount = _amount;
        transferRequest.numApprovals = 0;
        
        return currentRequestIndex;
    }

    function checkTransferRequestIsAtSendThreshold(uint currentNumApprovals) private view returns (bool) {
        return currentNumApprovals == requiredApprovals;
    }

    // ✅ When a transfer request has the required approvals, the transfer should be sent. 
    function sendTransferIfEnoughApprovals(uint _requestId) private {
        TransferRequest storage transferRequest = transferRequests[_requestId];

        if (checkTransferRequestIsAtSendThreshold(transferRequest.numApprovals)) {
            // send transfer
            payable(transferRequest.to).transfer(transferRequest.amount);
            balance -= transferRequest.amount;
        }
    }

    // ✅ Owners should be able to approve transfer requests.
    function approveTransferRequest(uint _requestId) public onlyOwners {
        TransferRequest storage transferRequest = transferRequests[_requestId];

        // ensure approval not already given by the owner
        require(transferRequest.approvals[msg.sender] != true, "You already approved this transfer request");
        // ensure transfer request is not already sent
        require(checkTransferRequestIsAtSendThreshold(transferRequest.numApprovals) == false, "This transfer request has already been sent");
        // ensure that the transfer request, if sent, is possible
        require(transferRequest.amount <= balance, "This transfer request is not possible with current balance. Please deposit more re-attempting approval!");

        transferRequest.approvals[msg.sender] = true;
        transferRequest.numApprovals += 1;

        sendTransferIfEnoughApprovals(_requestId);
    }
}