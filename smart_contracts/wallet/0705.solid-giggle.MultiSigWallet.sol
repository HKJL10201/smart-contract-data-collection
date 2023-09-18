pragma solidity 0.7.5;
pragma abicoder v2;

import "./Ownable.sol";

contract MultiSigWallet is Ownable {
    struct Trx {
		uint id;
		address from;
		address payable to;
		uint amount;
        bool completed; //track if the transfer has already gone through to prevent further unnecessary approvals
	}

    constructor(address[] memory _owners, uint _minApprovals) Ownable(_owners, _minApprovals) {}

	mapping(uint => address[]) outstandingTransfers; //Mapping of Transaction ID to List of Approvers
	Trx[] trxs; //Array to hold our transaction/transfer objects
	uint idCounter = 0;

	event transferRequested(address indexed from, address indexed to, uint amount);
    event txCreated(Trx trx);
	event transferApproved(address indexed approver, uint indexed txId);
    event transferCompleted(uint indexed txId, address to, uint amount);
    event approvalGranted(address indexed by, uint indexed forTx);

	function _getId() private returns(uint) {
		return idCounter++;
	}
	
	function deposit() external payable {}

    function getBalance() public view onlyOwners returns (uint) {
        return address(this).balance;
    }

	function requestTransfer(uint _amount, address payable _to) public onlyOwners returns(Trx memory) {
        require(_amount <= address(this).balance, "Insufficient Balance to Request Transfer");
		uint txId = _getId();
		Trx memory trx = Trx(txId, msg.sender, _to, _amount, false);
        emit txCreated(trx);

		outstandingTransfers[txId].push(msg.sender);
		emit transferRequested(msg.sender, _to, _amount);
        
        trxs.push(trx);
        return _initiateTransfer(txId, outstandingTransfers[txId].length);
	}

	function approveTransfer(uint _id) public onlyOwners returns(Trx memory) {
		address[] storage approvals = outstandingTransfers[_id];
		bool previouslyApproved = false;

		for(uint i = 0; i < approvals.length; i++) {
			if(approvals[i] == msg.sender) {
				previouslyApproved = true;
			}
		}

		require(!previouslyApproved, "Transfer previously approved");
		approvals.push(msg.sender);
        emit approvalGranted(msg.sender, _id);
		outstandingTransfers[_id] = approvals;
		
		return _initiateTransfer(_id, approvals.length);
	}

	function _initiateTransfer(uint _id, uint _approvals) private returns(Trx memory) {
		Trx memory trx = trxs[_id];

        if(_approvals >= minApprovals) {
            require(!trx.completed, "Transfer already completed");
            require(trx.amount <= address(this).balance, "Insufficient Balance to Complete Transfer");
			trx.to.transfer(trx.amount);
            emit transferCompleted(_id, trx.to, trx.amount);
            trx.completed = true;
		}

        return trx;
	}
}
