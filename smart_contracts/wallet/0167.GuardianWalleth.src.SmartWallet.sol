// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MultiSigWallet.sol";
import "./SocialRecovery.sol";
import "./Common.sol";

contract SmartWallet is Common{
    struct RecoveryWallet{
        SocialRecovery socialRecovery;
        MultiSigWallet multiSigWallet;
    }

    struct GuardianUIData{
        address guardianAddress;
        bool activated;
    }

    mapping(address => RecoveryWallet) wallets;
    mapping (address => address[]) approvingAddresses;
    mapping (address => address[]) guardingAddresses;

    //social recovery events
    event VoteCasted(address senderAddress, address walletOwner);
    event VoteRevoked(address senderAddress, address walletOwner);
    event GuardianAdditionInitiated(address sender, address guardian);
    event GuardianAdded(address sender, address guardian);
    event GuardianRemovalInitiated(address sender, address guardian);
    event GuardianRemoved(address sender, address guardian);

    //multi sig events
    event WalletCreated(address creator, address walletAddress);
    event ApproverAdded(address walletOwner, address approver);
    event ApprovalRequired(address approver, address initiator, address receiver, uint _amount,uint txIndex);
    event TransactionInitiated(address from, address to, uint amount);
    event TransactionApproved(address from, address owner, uint txIndex);
    event TransactionRevoked(address from, address owner, uint txIndex);
    event TransactionStatus(address _owner, uint _txIndex, uint numConfirmationsDone, uint numConfirmationsRequired);
    event TransactionDeleted(address sender, uint _txIndex);
    event ApprovalNotRequired(address approver, uint txIndex);
    event TransactionCompleted(address sender, uint _txIndex);
    event OwnerChanged(address guardian, address oldOwner, address newOwner);
    // event Deposit(TransactionType _type, uint256 _amount,address _token);

    function createNewSmartWallet(address[] memory _guardians, 
    address[] memory _approvers, 
    uint _numConfirmationsRequired,
    uint _inactivePeriod,
    uint _transactionLimit
    ) public {
       SocialRecovery sRecovery = new SocialRecovery(_guardians);
       for (uint i = 0; i < _guardians.length; i++) {
        guardingAddresses[_guardians[i]].push(msg.sender);
        emit GuardianAdded(msg.sender, _guardians[i]);
       }
       MultiSigWallet mWallet = new MultiSigWallet(_numConfirmationsRequired, _approvers, _inactivePeriod, _transactionLimit);
       for (uint i = 0; i < _approvers.length; i++) {
        approvingAddresses[_approvers[i]].push(msg.sender);
        emit ApproverAdded(msg.sender, _approvers[i]);
       }
       wallets[msg.sender] = RecoveryWallet(sRecovery, mWallet);
       emit WalletCreated(msg.sender, address(mWallet));
       //TODO: Store this mwallet address and listen to events in UI.
    }

    function deposit(uint256 _amount, address _token) external payable{

        (wallets[msg.sender].multiSigWallet).deposit{value: _amount}(msg.sender, _amount, _token);
    }

    // MultiSigWallet
    function initiateTransaction(address _to,uint _amount, TransactionType _type, address _token, bytes calldata _data) public {
        uint txIndex = wallets[msg.sender].multiSigWallet.initiateTransaction(_to, _amount, _type, _token, _data);
        uint numConfirmationsRequired = wallets[msg.sender].multiSigWallet.getNumberOfConfirmations();
        emit TransactionStatus(msg.sender, txIndex, 1, numConfirmationsRequired);
        address[] memory approvers = wallets[msg.sender].multiSigWallet.fetchApproverData();
        for(uint i;i<approvers.length;i++){
            emit ApprovalRequired(approvers[i], msg.sender,_to, _amount, txIndex);
        }
        //TODO: handle no wallet present for a user case.
        //Doubt: can we make this view? this doesn't the state of this contract but it does change of overall blockchain
    }

    function getNumberOfConfirmationsDone(uint _txIndex) external view returns(uint){
        uint result = wallets[msg.sender].multiSigWallet.getNumberOfConfirmationsDone(_txIndex);
        return result;
    }

    function approveTransaction(uint _txIndex, address _owner) external {
        uint numConfirmationsDone = wallets[_owner].multiSigWallet.approveTransaction(_txIndex);
        uint numConfirmationsRequired = wallets[_owner].multiSigWallet.getNumberOfConfirmations();
        emit TransactionApproved(msg.sender, _owner, _txIndex);
        emit TransactionStatus(_owner, _txIndex, numConfirmationsDone, numConfirmationsRequired);
    }

    function getApprovalStatus(uint _txIndex) external view returns(bool){
         bool result = wallets[msg.sender].multiSigWallet.getStatusOfYourApproval(_txIndex);
         return result;
    }

    function revokeTransaction(uint _txIndex, address _owner) external {
        uint numConfirmationsDone = wallets[_owner].multiSigWallet.revokeTransaction(_txIndex);
        uint numConfirmationsRequired = wallets[_owner].multiSigWallet.getNumberOfConfirmations();
        emit TransactionRevoked(msg.sender, _owner, _txIndex);
        emit TransactionStatus(_owner, _txIndex, numConfirmationsDone, numConfirmationsRequired);
    }

    function deleteTransaction(uint _txIndex) external {
        wallets[msg.sender].multiSigWallet.deleteTransaction(_txIndex);
        emit TransactionDeleted(msg.sender, _txIndex);
        address[] memory approvers = wallets[msg.sender].multiSigWallet.fetchApproverData();
        for(uint i;i<approvers.length;i++){
            emit ApprovalNotRequired(approvers[i], _txIndex);
        }
    }

    function publishTransaction(uint _txIndex) external {
        wallets[msg.sender].multiSigWallet.publishTransaction(_txIndex);
        emit TransactionCompleted(msg.sender, _txIndex);
        address[] memory approvers = wallets[msg.sender].multiSigWallet.fetchApproverData();
        for(uint i;i<approvers.length;i++){
            emit ApprovalNotRequired(approvers[i], _txIndex);
        }
    }

    // SocialRecovery
    function castRecoveryVote(address oldWalletOwner, address _newOwnerAddress) public{
       bool isOwnerChanged = wallets[oldWalletOwner].socialRecovery.castVote(_newOwnerAddress);

       emit VoteCasted(msg.sender, oldWalletOwner);
       if(isOwnerChanged){
           address[] memory guardians = wallets[oldWalletOwner].socialRecovery.fetchExistingList();
           RecoveryWallet memory moveWallet = wallets[oldWalletOwner];
           delete wallets[oldWalletOwner];
           wallets[_newOwnerAddress] = moveWallet;
           wallets[_newOwnerAddress].multiSigWallet.changeOwner(_newOwnerAddress);
           for(uint i;i< guardians.length;i++){
               emit OwnerChanged(guardians[i], oldWalletOwner, _newOwnerAddress);
           }
       }
    }

    //TODO: Function to fetch casted votes by a guardian when they try to login

    function removeRecoveryVote(address walletOwner) public{
        wallets[msg.sender].socialRecovery.removeVote(msg.sender);
        emit VoteRevoked(msg.sender, walletOwner);
    }

    function initiateAddGuardian(address _guardian) public {
        wallets[msg.sender].socialRecovery.initiateAddGuardian(_guardian);
        emit GuardianAdditionInitiated(msg.sender, _guardian);
    }

    function activateGuardian(address _guardian) public {
        wallets[msg.sender].socialRecovery.activateGuardian(_guardian);
        guardingAddresses[_guardian].push(msg.sender);
        emit GuardianAdded(msg.sender, _guardian);
    }

    function initiateGuardianRemoval(address _guardian) public{
        wallets[msg.sender].socialRecovery.initiateGuardianRemoval(_guardian);
        emit GuardianRemovalInitiated(msg.sender, _guardian);
    }

    function removeGuardian(address _guardian) public {
        wallets[msg.sender].socialRecovery.removeGuardian(_guardian);
        removeElementFromArray(_guardian, msg.sender);
        emit GuardianRemoved(msg.sender, _guardian);
    }

    function removeElementFromArray(address guardian, address element) internal {
        uint i;
        address[] storage addressArray = guardingAddresses[guardian];
        uint length = addressArray.length;
        for(i;i<length;i++){
            if (addressArray[i] == element) {
                break;
            }
        }
        addressArray[i] = addressArray[length-1];
        addressArray.pop();
    }
    
    
 //-----------------Call on Login ----------------------------------------

    
    function fetchGuardianData()public view returns (GuardianUIData[] memory){
        address[] memory existingGuardians = wallets[msg.sender].socialRecovery.fetchExistingList();
        GuardianUIData[] memory result = new GuardianUIData[](existingGuardians.length);
        for(uint i;i< existingGuardians.length;i++){
            result[i] = GuardianUIData(existingGuardians[i], wallets[msg.sender].socialRecovery.fetchGuardianStatus(existingGuardians[i]));
        }
        return result;
    }

    function fetchApproverData()public view returns (address[] memory){
        return wallets[msg.sender].multiSigWallet.fetchApproverData();
    }

    function fetchTxData()public view returns(uint, uint, uint){
        return wallets[msg.sender].multiSigWallet.fetchTxData();
    }

    function fetchApproversOf()public view returns (address[] memory){
        return approvingAddresses[msg.sender];
    }

    function fetchGuardingAddresses()public view returns (address[] memory){
        return guardingAddresses[msg.sender];
    }

    function fetchMultiSig() public view returns (address walletAddress){
        return address(wallets[msg.sender].multiSigWallet);
    }

    function getTransaction(uint _txIndex) external view returns(uint,address){
        (address to, uint amount)= wallets[msg.sender].multiSigWallet.getTransaction(_txIndex);
        return ( amount, to);
    }

    function getActiveTransactions() public view returns(TransactionUIData[] memory result){
        return wallets[msg.sender].multiSigWallet.getActiveTransactions();
    }

    function fetchTransactionsRequiringApprovals() external view returns(TransactionUIData[] memory result){
        address[] memory childAccounts = approvingAddresses[msg.sender];
        uint maxTxShow =10;
        result = new TransactionUIData[](maxTxShow);        
        uint count;
        for(uint i;i< childAccounts.length;i++){
            TransactionUIData[] memory txArray = wallets[childAccounts[i]].multiSigWallet.getActiveTransactions();
            for(uint j;j<txArray.length;j++){
                result[count] = txArray[j];
                count++;
                if(count>=maxTxShow){
                    break;
                } 
            }
        }
        return result;
    }
}
