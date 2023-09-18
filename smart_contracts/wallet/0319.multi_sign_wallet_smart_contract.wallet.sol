pragma solidity ^0.8.0;
pragma abicoder v2;

contract Wallet {
    address[] public owners;
    uint256 limit;

    struct Transfer {
        uint256 amount;
        address payable receiver;
        uint256 approvals;
        bool hasBeenSent;
        uint256 id;
    }

    event TransferRequestCreated(
        uint256 _id,
        uint256 _amount,
        address _initiator,
        address _receiver
    );
    event ApprovalReceived(uint256 _id, uint256 _approvals, address _approver);
    event TransferApproved(uint256 _id);

    Transfer[] transferRequests;

    mapping(address => mapping(uint256 => bool)) approvals;

    //Only owner(s) can continue the execution.
    modifier onlyOwners() {
        bool owner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                owner = true;
            }
        }
        require(owner == true);
        _;
    }

    // Initialize the owners list and the limit
    constructor(address[] memory _owners, uint256 _limit) {
        owners = _owners;
        limit = _limit;
    }

    //Empty function
    function deposit() public payable {}

    //Create an instance of the Transfer struct and add it to the transferRequests array
    function createTransfer(uint256 _amount, address payable _receiver)
        public
        onlyOwners
    {
        emit TransferRequestCreated(
            transferRequests.length,
            _amount,
            msg.sender,
            _receiver
        );
        transferRequests.push(
            Transfer(_amount, _receiver, 0, false, transferRequests.length)
        );
    }

    function approve(uint256 _id) public onlyOwners {
        require(approvals[msg.sender][_id] == false);
        require(transferRequests[_id].hasBeenSent == false);

        approvals[msg.sender][_id] = true;
        transferRequests[_id].approvals++;

        emit ApprovalReceived(_id, transferRequests[_id].approvals, msg.sender);

        if (transferRequests[_id].approvals >= limit) {
            transferRequests[_id].hasBeenSent = true;
            transferRequests[_id].receiver.transfer(
                transferRequests[_id].amount
            );
            emit TransferApproved(_id);
        }
    }

    //Should return all transfer requests
    function getTransferRequests() public view returns (Transfer[] memory) {
        return transferRequests;
    }
}
