pragma solidity >=0.4.21 <0.6.0;
pragma experimental ABIEncoderV2;

contract MultiSignatureWallet {
    
    uint public minNumberOfApprovers;
    uint public approvalsCount;
    uint public balance;

    address payable public beneficiary;
    address payable public owner;

    mapping (address => bool) approvedBy;
    mapping (address => bool) isApprover;

    event Transferred(address from, uint amount);

    constructor(address[] memory _approvers, uint _minNumberOfApprovers, address payable _beneficiary) public payable {
        require(_minNumberOfApprovers <= _approvers.length, "Number of approvers less than required number.");

        minNumberOfApprovers = _minNumberOfApprovers;
        beneficiary = _beneficiary;
        owner = msg.sender;

        for (uint i = 0; i < _approvers.length; i++) {
            address approver = _approvers[i];
            isApprover[approver] = true;
        }
    }

    function donate() public payable {
        balance += msg.value;
    }

    function approve(address signer) public {
        require(isApprover[signer], "Not an approver.");

        if (!approvedBy[signer]) {
            approvedBy[signer] = true;
            approvalsCount++;
        }
    }

    function sendToBeneficiary() public payable {
        require(approvalsCount >= minNumberOfApprovers, "Not approved");

        uint amount = balance; 
        beneficiary.transfer(amount); 
        emit Transferred(msg.sender, amount);
    }

    function reject() public {
        require(isApprover[msg.sender], "Not an approver.");

        selfdestruct(owner);
    }
}