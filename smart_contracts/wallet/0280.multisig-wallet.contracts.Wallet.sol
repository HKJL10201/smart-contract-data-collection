pragma solidity 0.7.5;
pragma abicoder v2;

contract Wallet {
    address[] public owners;
    uint256 limit;

    struct Transfer{
        uint256 amount;
        address payable receiver;
        uint256 approvals;
        bool hasBeenSent;
        uint256 id;
    }

    mapping(address => mapping(uint256 => bool)) approvals;
    mapping(address => uint256) balance;

    Transfer[] transferRequests;

    event Deposit(uint256 amount, address indexed depositedFor);
    event TransferRequestCreated(uint256 id, uint256 amount, address from, address to);
    event ApprovalReceived(uint256 id, uint256 approvals, address approver);
    event TransferApproved(uint256 id);
    event Withdraw(uint256 amount, address depositor);

    // should allow only thos in owners list to execute function
    modifier onlyOwners(){
       bool owner = false;
       for(uint i=0; i<owners.length; i++){
           if(owners[i] = msg.sender){
               owner = true;
           }
       }
       require(owner = true, "Not authorized");
    _;
    }

    // initalize the owner list and the limit
    constructor(address[] memory _owners, uint256 _limit){
        owners = _owners;
        limit = _limit;
    }

    // function to deposti funds
    function deposit() public payable returns (uint256) {
        balance[msg.sender] += msg.value;
        emit Deposit(msg.value, msg.sender);
        return balance[msg.sender];
    }

    // function to withdraw funds
    function withdraw(uint256 amount) public onlyOwners returns (uint256) {
        require(balance[msg.sender] >= amount, "Insufficient funds");
        msg.sender.transfer(amount);
        emit Withdraw(amount, msg.sender);
        return balance[msg.sender];        
    }

    // get balance of the account owner
    function getBalance() public view returns (uint256) {
        return balance[msg.sender];
    }

    // transfer funds to a recipient
    function createTransfer(address payable recipient, uint256 amount) public onlyOwners {
        require(balance[msg.sender] >= amount, "Insufficient funds");
        require(msg.sender != recipient, "Transfer to same account");
        emit TransferRequestCreated(transferRequests.length, amount, msg.sender, recipient);

        transferRequests.push(Transfer(amount, receiver, 0, false, transferRequests.length));
    }

    /** Set approval fo transfer request
    Update the Transfer struct
    Update mapping to record the approval
    When the amount of approvals for the transfer has reached the limit, 
    send the transfer to the recipient.
    Wallet owners can only vote once.
    Wallet owner cannot vote on transfer that has already executed.
    */
    function approveTransfer(uint256 id) public onlyOwners {
        require(approvals[msg.sender][id] == false);
        require(transferRequests[id].hasBeenSent == false);

        approvals[msg.sender][id] = true;
        transferRequests[id].approvals++;

        emit ApprovalReceived(id, transferRequests[id].approvals, msg.sender);

        if(transferRequests[id].approvals >= limit){
            transferRequests[id].hasBeenSent = true;
            transferRequests[id].receiver.tranfer(transferRequests[id].amount);

            emit TransferApproved(id);
        }
    }

    // return all transfer requests
    function getTransfers() public view returns (Transfer[] memory){
        return transferRequests;
    }

}