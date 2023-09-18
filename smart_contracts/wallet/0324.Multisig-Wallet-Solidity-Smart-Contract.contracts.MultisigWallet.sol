pragma solidity 0.8.14;

contract MultisigWallet {
    uint percentageToAgree;

    address[] approvers;

    mapping(uint => string) description;
    mapping(uint => uint) amount;
    mapping(uint => address payable) receiver;
    mapping(uint => uint) approvals;
    mapping(uint => bool) withdrawRequestFinished;
    mapping(uint => bool) needsToWithdraw;
    mapping(uint => mapping(address => bool)) hasVoted;
    mapping(uint => mapping(address => bool)) currentVote;

    uint iterator;

    constructor(address[] memory _approvers, uint _percentageToAgree) {
        approvers = _approvers;
        percentageToAgree = _percentageToAgree;
        iterator = 0;
    }

    modifier onlyApprover() {
        bool isApprover = false;
        for (uint i = 0; i < approvers.length; i++) {
            if (approvers[i] == msg.sender) {
                isApprover = true;
                break;
            }
        }

        require(isApprover == true,"only an approver can call this function");
        _;
    }

    function requestTransaction(uint _amount, address payable _receiver, string memory _description) public onlyApprover {
        description[iterator] = _description;
        amount[iterator] = _amount;
        receiver[iterator] = _receiver;
        approvals[iterator] = 1;
        hasVoted[iterator][msg.sender] = true;
        currentVote[iterator][msg.sender] = true;
        withdrawRequestFinished[iterator] = false;
        needsToWithdraw[iterator] = false;

        iterator++;
    }

    function voteOnTransaction(uint _id, bool _voteValue) public onlyApprover {
        require(withdrawRequestFinished[_id] == false, "withdraw must be still active");
        require(hasVoted[_id][msg.sender] == false, "this address has already voted");
        hasVoted[_id][msg.sender] = true;
        currentVote[_id][msg.sender] = _voteValue;

        checkIfWithdrawRequestFinished(_id);
    }

    function checkIfWithdrawRequestFinished(uint _id) public {
        uint amountToApprove = approvers.length * percentageToAgree / 100;
        approvals[_id] = 0;

        for (uint i = 0; i < approvers.length; i++) {
            if (currentVote[_id][approvers[i]] == true) {
                approvals[_id]++;
                if (approvals[_id] >= amountToApprove) {

                    needsToWithdraw[_id] = true;
                }
            }
        }
    }

    function withdraw(uint _id) public {
        require(withdrawRequestFinished[_id] == false, "withdraw request must not be finished");
        require(needsToWithdraw[_id] == true, "this withdraw request has not been approved to transact");
        require(approvals[_id] > 1, "approvals has to have more than 1 address approving");

        bool canApprove = false;
        for (uint i = 0; i < approvers.length; i++) {

            if (approvers[i] == msg.sender || receiver[_id] == msg.sender) {
                canApprove = true;
                break;
            }
        }

        require(canApprove == true,"only approved address can call this function");
        
        needsToWithdraw[_id] = false;
        withdrawRequestFinished[_id] = true;
        receiver[_id].transfer(amount[_id]);
    }

    function deposit() public payable {}

    function getDescription(uint _id) public view returns(string memory) {
        return description[_id];
    }

    function getTransactionRequest(uint _id) public view returns(string memory, uint, address payable, uint, bool, bool) {
        return (description[_id], amount[_id], receiver[_id], approvals[_id], withdrawRequestFinished[_id], needsToWithdraw[_id]);
    }

    function getHasVoted(uint _id, address _address) public view returns(bool) {
        return hasVoted[_id][_address];
    }
    
    function getCurrentVote(uint _id, address _address) public view returns(bool) {
        return currentVote[_id][_address];
    }

    function getApprovalPercentageToPass() public view returns(uint) {
        return percentageToAgree;
    }
}