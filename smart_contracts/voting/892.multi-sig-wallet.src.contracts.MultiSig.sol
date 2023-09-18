pragma solidity 0.8.12;
pragma abicoder v2;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiSig {

    address contractOwner = 0xF9108C5B2B8Ca420326cBdC91D27c075ea60B749;
    address[] public approvers = [
        0xF9108C5B2B8Ca420326cBdC91D27c075ea60B749,
        0x7ab8a8dC4A602fAe3342697a762be22BB2e46d4d,
        0x813426c035f2658E50bFAEeBf3AAab073D956F31,
        0x9A3A8Db1c09cE2771A5e170a01a2A3eFB93ADA17,
        0x89Ca0E3c4b93D9Ee8b1C1ab89266F1f6bA11Aa22
    ];
    event Deposit(address indexed fromThisGuy, uint valueGuy);
    event alertNewApproval(address indexed fromGuy, address sendToGuy, string  reasonGuy, uint amountGuy, uint idGuy, string tokenSymbol);
    event Approval(address indexed signer, uint requestId, uint approvalId);
    event Payment(uint requestId, bool didSucceed, uint paymentAmount);


    bool contractHasLaunched = false;
    uint voteApprovalThreshold = 3;
    uint256 contractBalance = address(this).balance;

    modifier onlyCustodians(){
        bool owner = false;
        for (uint i=0; i<approvers.length; i++){
            if (approvers[i] == msg.sender){
                owner = true;
            }
        }
        require(owner==true, "only custodians may call this function.");
        _;
    }

    modifier onlyContractOwner(){
        require(msg.sender == contractOwner, "only contract owner may call this function.");
        _;
    }



    function setVoteApprovalThreshold(uint thresholdPercentage) public {
        require(msg.sender == contractOwner, "Only owner can call this");
        voteApprovalThreshold = thresholdPercentage;
    }

    struct Custodian {
        address thisAddress;
        uint voteWeight;
    }
    Custodian[] custodians;

    function getContractOwner() public view returns (address) {
        return(contractOwner);
    }
    
    function firstRun() onlyContractOwner public returns(string memory){
        if(contractHasLaunched == false){
            if (msg.sender != contractOwner){
                return('only contract owner can run this function.');
            }
            else {
                for (uint256 i = 0; i < approvers.length; i++) {
                    Custodian memory newRequest = Custodian(approvers[i], 1);
                    custodians.push(newRequest);
                }
                contractHasLaunched = true;
                return('set approvers, vote weight, and voteApprovalThreshold!');
            }
        }
        else{
            return('contract has already been launched.');
        }
    }



    struct Requests {
        address payable receipient;
        uint id;
        uint amount;
        string _reason;
        uint status;
        address contractAddress;
        string tokenSymbol;
        
    }
    Requests[] transferRequests;
   
    struct ApprovalStruct {
        uint proposalId;
        address custodianMember;
        uint status; //0 untouched. 1 approved. 2 rejected
        
    }


    mapping(uint => mapping(address=> uint)) public approvedStatus;
 
    function getApprovalStatus(uint _requestId) public view returns(ApprovalStruct [] memory)  {
        ApprovalStruct [] memory custodianApprovals = new ApprovalStruct[](approvers.length);

        for (uint i=0; i < approvers.length; i++) {
            ApprovalStruct memory newCustodianApprovals = ApprovalStruct(_requestId, approvers[i], approvedStatus[ _requestId ][ approvers[i] ]);
            custodianApprovals[i] = newCustodianApprovals;
        }
        return(custodianApprovals);
    }

    function getVoteThreshold() public view returns(uint){
        return voteApprovalThreshold;
    }

    // function calculateRejectCount(uint _requestId) public view returns(uint) {
    //     ApprovalStruct [] memory custodianApprovals = new ApprovalStruct[](approvers.length);
    //     uint _totalRejected = 0;
    //     for (uint i=0; i < approvers.length; i++) {
    //         ApprovalStruct memory newCustodianApprovals = ApprovalStruct(_requestId, approvers[i], approvedStatus[ _requestId ][ approvers[i] ]);
    //         custodianApprovals[i] = newCustodianApprovals;
    //         if (approvedStatus[ _requestId ][ approvers[i] ] == 2){
    //             _totalRejected = _totalRejected+1;
    //         }
    //     }
    //     return(_totalRejected);
    // }
    function calculateRejectCount() public view returns(uint [] memory) {
        ApprovalStruct [] memory custodianApprovals = new ApprovalStruct[](approvers.length);
        uint[] memory _totalRejected; 
        for (uint q=0; q < transferRequests.length; q++){
            for (uint i=0; i < approvers.length; i++) {
                ApprovalStruct memory newCustodianApprovals = ApprovalStruct(q, approvers[i], approvedStatus[q ][ approvers[i] ]);
                custodianApprovals[i] = newCustodianApprovals;
                if (approvedStatus[ q ][ approvers[i] ] == 2){
                    _totalRejected[q] = _totalRejected[q]+1;
                }
            }

        }
        return(_totalRejected);
    }
    function calculateVotedCount(uint _requestId) public view returns(uint _totalVoted) {
        ApprovalStruct [] memory custodianApprovals = new ApprovalStruct[](approvers.length);
        uint totalVoted = 0;

        for (uint i=0; i < approvers.length; i++) {
            ApprovalStruct memory newCustodianApprovals = ApprovalStruct(_requestId, approvers[i], approvedStatus[ _requestId ][ approvers[i] ]);
            custodianApprovals[i] = newCustodianApprovals;
            if (approvedStatus[ _requestId ][ approvers[i] ] != 0){
                totalVoted = totalVoted+1;
            }
        }
        return(totalVoted);
    }
    function calculateApprovalCount(uint _requestId) public view returns(uint _totalApproval) {
        ApprovalStruct [] memory custodianApprovals = new ApprovalStruct[](approvers.length);
        uint totalApproval1 = 0;


        for (uint i=0; i < approvers.length; i++) {
            ApprovalStruct memory newCustodianApprovals = ApprovalStruct(_requestId, approvers[i], approvedStatus[ _requestId ][ approvers[i] ]);
            custodianApprovals[i] = newCustodianApprovals;

            if (approvedStatus[ _requestId ][ approvers[i] ] == 1){
                totalApproval1 = totalApproval1 + 1;
            }
        }
        return(totalApproval1 );
    }


    // function getIdToTokenSymbol(uint id) public view returns(string memory tokenSymbol){
    //     return(transferRequests[id].tokenSymbol);
    // }

    function sendTokens(uint id) onlyContractOwner public {
        require(msg.sender == contractOwner, "Only owner can call this");
        
        uint tallyVotes     = calculateApprovalCount(id);
        uint tallyApprovals = calculateVotedCount(id);

        require(tallyApprovals >= voteApprovalThreshold, "not enough approvals to take action.");
        require(transferRequests[id].status != 2, "proposal has already been executed.");
        require((tallyVotes <= tallyApprovals) && (tallyVotes >= voteApprovalThreshold), "proposal has failed to meet threshold");

        if (transferRequests[id].contractAddress == 0x0000000000000000000000000000000000000000  ) {
            transferRequests[id].receipient.transfer(transferRequests[id].amount); //native coin (ETH/MATIC)
            transferRequests[id].status = 2;
            emit Payment(id, true, transferRequests[id].amount);
        }else {
            transferERC20(IERC20(transferRequests[id].contractAddress), transferRequests[id].receipient, transferRequests[id].amount);
            transferRequests[id].status = 2;
            emit Payment(id, true, transferRequests[id].amount);
        }
    }

 
    function getAllApprovalRequests() public view returns (Requests [] memory, ApprovalStruct[][] memory){ 
        ApprovalStruct [][] memory tempApprovalStatusArray = new ApprovalStruct[][](transferRequests.length);
        for (uint i=0; i < transferRequests.length; i++) {
            tempApprovalStatusArray[i] = getApprovalStatus(transferRequests[i].id);
        }
        return(transferRequests, tempApprovalStatusArray);
    }

    function newApproval(address payable _sendTo, string memory _reason, uint _amount, bool isErc20, address contractAddress, string memory tokenSymbol) onlyCustodians public {

        if (isErc20 == true){
            Requests memory newRequest = Requests(_sendTo, transferRequests.length, _amount, _reason, 1, contractAddress, tokenSymbol); 
            transferRequests.push(newRequest);                                                           
            emit alertNewApproval(msg.sender, _sendTo, _reason, _amount, transferRequests.length, tokenSymbol);
        }else {
            Requests memory newRequest = Requests(_sendTo, transferRequests.length, _amount, _reason, 1, 0x0000000000000000000000000000000000000000, 'devEth'); //1 is 'open' status, 0x00 
            transferRequests.push(newRequest);                                                           
            emit alertNewApproval(msg.sender, _sendTo, _reason, _amount, transferRequests.length, 'devEth');
        }
        
        
    }

    function depositEth() public payable {
        contractBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function getContractBalance() public view returns(uint){
        // return contractBalance;
        // // return address(this).balance;
        return address(this).balance;
    }


    function approveRequest(uint _requestId, uint thisApproval) public {
        if ((thisApproval != 0) && (thisApproval != 1) && (thisApproval!=2)){return();}
        approvedStatus[_requestId][msg.sender] = thisApproval;
        emit Approval(msg.sender, _requestId, thisApproval);
    }

    function getCustodians() public view returns (Custodian [] memory){
        return(custodians);
    }
    
    function transferERC20(IERC20 token, address to, uint256 amount) public {
        require(msg.sender == contractOwner, "Only the contract owner can withdraw funds");
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to,amount);

    }



}