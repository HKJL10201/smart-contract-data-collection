// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.9;

/**
 * @title Multi Sig Wallet
 * @dev Multi-Sig Contract enables multiple people
 * to collectively sign a transaction
 */
contract MultiSig {
    struct Transfer {
        uint256 amount;
        address payable receiver;
        uint256 approvals;
        bool sent;
    }

    mapping(address => bool) public owners;
    mapping(address => mapping(uint256 => bool)) public approvals;
    mapping(address => uint256) public deposits;
    uint8 public immutable limit;

    uint256 public nonce;
    mapping(uint256 => Transfer) public transferRequests;

    event TransferRequestCreated(
        address indexed _initiator,
        address indexed _receiver,
        uint256 _nonce,
        uint256 _amount
    );

    event ApprovalReceived(
        address indexed _approver,
        uint256 _nonce,
        uint256 _approvals
    );

    event TransferApproved(uint256 _nonce);
    event Deposited(address indexed _account, uint256 _amount);

    /**
     * @dev Ensures that only the owners can access this feature
     */
    modifier onlyOwners() {
        require(owners[msg.sender] == true, "Access is denied");
        _;
    }

    /**
     * @dev Constructs this contract
     * @param _owners Enter the addresses which will
     * become the owners
     * @param _limit Specify the minimum number of approvals
     * required to confirm a transaction
     */
    constructor(address[] memory _owners, uint8 _limit) {
        for (uint256 i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = true;
        }

        limit = _limit;

        // emit -->
    }

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Creates an instance of the Transfer struct and add it to the transferRequests array
    function createTransfer(uint256 _amount, address payable _receiver)
        external
        onlyOwners
    {
        transferRequests[nonce] = Transfer(_amount, _receiver, 0, false);
        emit TransferRequestCreated(msg.sender, _receiver, nonce, _amount);

        nonce++;
    }

    // Called to approve of a transfer request.
    // Transfers money if minimum approval number is met.
    function approve(uint256 _nonce) external onlyOwners {
        require(approvals[msg.sender][_nonce] == false, "Already approved");
        require(transferRequests[_nonce].sent == false, "Already sent");

        approvals[msg.sender][_nonce] = true;
        transferRequests[_nonce].approvals++;

        emit ApprovalReceived(
            msg.sender,
            _nonce,
            transferRequests[_nonce].approvals
        );

        if (transferRequests[_nonce].approvals >= limit) {
            transferRequests[_nonce].sent = true;
            transferRequests[_nonce].receiver.transfer(
                transferRequests[_nonce].amount
            );
            emit TransferApproved(_nonce);
        }
    }
}
