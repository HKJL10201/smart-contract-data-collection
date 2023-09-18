// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ReentrancyGuard } from "openzeppelin/security/ReentrancyGuard.sol";
import { Initializable } from "openzeppelin/proxy/utils/Initializable.sol";
import { IERC721Receiver } from "openzeppelin/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import { EnumerableSet } from  "openzeppelin/utils/structs/EnumerableSet.sol";
import { ECDSA } from "openzeppelin/utils/cryptography/ECDSA.sol";
import { BaseAccount } from "account-abstraction/core/BaseAccount.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import { Proxiable } from "./Proxy/Proxiable.sol";
import { MyWalletStorage } from "./MyWalletStorage.sol";

import "forge-std/console.sol";

/**
 * @title MyWallet
 * @notice A contract wallet implement features including: multisig, social recovery, 
 *  freeze wallet and whitelist.
 * Note: this is a final project for Appworks school blockchain program #2
 * @author Jimbo
 */
contract MyWallet is Proxiable, ReentrancyGuard, Initializable, BaseAccount, IERC721Receiver, IERC1155Receiver, MyWalletStorage{

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using ECDSA for bytes32;

    /**********************
     *   events 
     **********************/
    /// @notice emitted when owner submit a tx
    event SubmitTransaction(address indexed sender, uint256 indexed transactionIndex);

    /// @notice emitted when owner confirm a tx
    event ConfirmTransaction(address indexed sender, uint256 indexed transactionIndex);

    /// @notice emitted when transaction with transactionIndex passed
    event TransactionPassed(uint256 indexed transactionIndex);

    /// @notice emitted when a tx excuted
    event ExecuteTransaction(uint256 indexed transactionIndex);

    /// @notice emitted when wallet receive ether
    event Receive(address indexed sender, uint256 indexed amount, uint256 indexed balance);

    /// @notice emitted when guardian submit recovery
    event SubmitRecovery(address indexed replacedOwner, address indexed newOwner, address proposer);

    /// @notice emitted when owner execute recovery
    event ExecuteRecovery(address indexed oldOwner, address indexed newOwner);

    /// @notice emitted when add a new white list
    event AddNewWhiteList(address indexed whiteAddr);

    /// @notice emitted when remove a address from white list
    event RemoveWhiteList(address indexed removeAddr);

    /// @notice emitted when replace a guardian
    event ReplaceGuardian(bytes32 indexed oldGuardianHash, bytes32 indexed newGuardianHash);

    /// @notice emitted when freeze wallet
    event FreezeWallet();

    /// @notice emitted when wallet unfreeze succefully
    event UnfreezeWallet();

    /// @notice emitted when initialization
    event Initialized();

    /**********************
     *   errors
     **********************/
    error AlreadyUnfreezeBy(address addr);
    error AlreadyRecoverBy(address addr);
    error AlreadyAnOwner(address addr);
    error AlreadyOnWhiteList(address addr);
    error AlreadyAGuardian(bytes32 guardianHash);
    error InvalidAddress();
    error ExecuteFailed();
    error InvalidTransactionIndex();
    error WalletIsRecovering();
    error WalletIsNotRecovering();
    error NotOwner();
    error NotGuardian();
    error NotFromWallet();
    error StatusNotPass();
    error TxAlreadyConfirmed();
    error TxAlreadyExecutedOrOverTime();
    error WalletFreezing();
    error WalletIsNotFrozen();
    error SupportNumNotEnough();
    error NoOwnerOrGuardian();
    error InvalidThreshold();
    error NotOnWhiteList();

    /**********************
     *  modifiers 
     **********************/
    modifier onlyOwner(){
        if (msg.sender == address(entryPointErc4337)){

            if (signedByOwner == address(0)){
                resetSignedByGuardian();
                revert NotOwner();
            }

        }else if(!owners.contains(msg.sender)){
            revert NotOwner();
        }
        _;
    }

    modifier onlyGuardian() {
        if (msg.sender == address(entryPointErc4337)){
            console.log("signedByGuardian in onlyGuardian = %s", signedByGuardian);
            if (signedByGuardian == address(0)){
                resetSignedByOwner();
                revert NotGuardian();
            }
        }else if(
            !guardianHashes.contains(keccak256(abi.encodePacked(msg.sender)))
        ){
            revert NotGuardian();
        }
        _;
    }

    /**
     * @dev for functions designed to be called by executeTransaction
     */
    modifier onlyExecuteByWallet() {
        if(msg.sender != address(this)){
            revert NotFromWallet();
        }
        _;
    }

    /**********************
     *   constructor
     **********************/
    constructor(IEntryPoint _entryPoint) MyWalletStorage(_entryPoint) {
        _disableInitializers();
    }

    /**********************
     *   initialize
     **********************/
    function initialize(
        address[] memory _owners,
        uint256 _leastConfirmThreshold,
        bytes32[] memory _guardianHashes,
        uint256 _recoverThreshold,
        address[] memory _whiteList
    ) public initializer
    {
        if(_owners.length == 0 || _guardianHashes.length == 0) {
            revert NoOwnerOrGuardian();
        }

        if(
            _leastConfirmThreshold == 0 ||
            _recoverThreshold == 0 ||
            _leastConfirmThreshold > _owners.length ||
            _recoverThreshold > _guardianHashes.length
        ){
            revert InvalidThreshold();
        }

        // owners
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if(owner == address(0)){
                revert InvalidAddress();
            }

            if(!owners.add(owner)){
                revert AlreadyAnOwner(owner);
            }
        }

        leastConfirmThreshold = _leastConfirmThreshold;

        // guardian hashes
        for (uint256 i = 0; i < _guardianHashes.length; i++) {
            bytes32 h = _guardianHashes[i];

            if(!guardianHashes.add(h)){
                revert AlreadyAGuardian(h);
            }
        }

        recoverThreshold = _recoverThreshold;

        // whitelist, if any
        if(_whiteList.length > 0){
            for (uint256 i = 0; i < _whiteList.length; i++) {
                address whiteAddr = _whiteList[i];
                _addWhiteList(whiteAddr);
            }
        }

        emit Initialized();
    }

    /************************
     *   multisig functions
     ************************/

    /**
     * @notice owner submit transactions before multisig
     * @param  _to is the tartget address
     * @param _value is the value with the tx
     * @param _data is the calldata of the tx
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyOwner
        returns(uint256 _transactionIndex)
    {
        if(msg.sender == address(entryPointErc4337)){
            _transactionIndex = _submitTransaction(_to, _value, _data, signedByOwner);
            resetSignedByOwner();
        } else {
            _transactionIndex = _submitTransaction(_to, _value, _data, msg.sender);
        }
    }

    function _submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data,
        address _owner
    ) 
        internal 
        returns(uint256 _transactionIndex) 
    {
        _transactionIndex = transactionList.length;
        transactionList.push(
            Transaction({
                status: TransactionStatus.PENDING,
                to: _to,
                value: _value,
                data: _data,
                confirmNum: 0,
                untilTimestamp: block.timestamp + overTimeLimit
            })
        );

        emit SubmitTransaction(_owner, _transactionIndex);
    }

    /**
     * @notice get transaction information
     * @param _transactionIndex is the index of transactionList
     */
    function getTransactionInfo(uint256 _transactionIndex)
        external
        view
        returns(
            TransactionStatus,
            address,
            uint256,
            bytes memory,
            uint256,
            uint256
        )
    {
        Transaction storage txn = transactionList[_transactionIndex];
        return (
            _getTransactionStatus(_transactionIndex),
            txn.to,
            txn.value,
            txn.data,
            txn.confirmNum,
            txn.untilTimestamp
        );
    }

    /**
     * @notice confirm transaction to pass multisig process
     * @dev tx status will be PASS if tx's to address is on white list or the confirmNum > threshold
     */
    function confirmTransaction(uint256 _transactionIndex)
        public
        onlyOwner
    {
        if(msg.sender == address(entryPointErc4337)){
            _confirmTransaction(_transactionIndex, signedByOwner);
            resetSignedByOwner();
        } else {
            _confirmTransaction(_transactionIndex, msg.sender);
        }
    }

    function _confirmTransaction(uint256 _transactionIndex, address _owner) internal {
        _isIndexValid(_transactionIndex);
        // already confirmed
        if(isConfirmed[_transactionIndex][_owner]){
            revert TxAlreadyConfirmed();
        }

        TransactionStatus status= _getTransactionStatus(_transactionIndex);
        // EXECUTED or OVERTIME
        if(
            status == TransactionStatus.EXECUTED ||
            status == TransactionStatus.OVERTIME
        ){
            revert TxAlreadyExecutedOrOverTime();
        }

        Transaction storage txn = transactionList[_transactionIndex];
        isConfirmed[_transactionIndex][_owner] = true;
        // PASS
        if(
            ++txn.confirmNum >= leastConfirmThreshold || // over threshold
            whiteList.contains(txn.to) // on white list
        ){
            txn.status = TransactionStatus.PASS;
            emit TransactionPassed(_transactionIndex);
        }
        // else, txn.status remains PENDING
        emit ConfirmTransaction(_owner, _transactionIndex);
    }

    /**
     * @notice Execute the transaction
     * @dev everyone can call this, only passed transaction can be executed
     * @dev revert if wallet is freezing
     */ 
    function executeTransaction(uint256 _transactionIndex) 
        public
        nonReentrant
    {
        if (msg.sender == address(entryPointErc4337)) {
            resetSignedByGuardian();
            resetSignedByOwner();
        }
        
        _executeTransaction(_transactionIndex);
    }

    function _executeTransaction(uint256 _transactionIndex) internal {
        _isIndexValid(_transactionIndex);
        if(isFreezing){
            revert WalletFreezing();
        }

        Transaction storage txn = transactionList[_transactionIndex];
        if(txn.status != TransactionStatus.PASS){
            revert StatusNotPass();
        }

        txn.status = TransactionStatus.EXECUTED;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        if(!success){
            revert ExecuteFailed();
        }

        emit ExecuteTransaction(_transactionIndex);
    }

    /**
     * @notice get transaction's status
     * @param _transactionIndex index of transactionList
     */
    function _getTransactionStatus(uint256 _transactionIndex) internal view returns(TransactionStatus){
        Transaction storage txn = transactionList[_transactionIndex];
        // EXECUTED
        if(txn.status == TransactionStatus.EXECUTED){
            return TransactionStatus.EXECUTED;
        }
        // OVERTIME
        if(block.timestamp > txn.untilTimestamp){
            return TransactionStatus.OVERTIME;
        }
        // PENDING or PASS
        return txn.status;
    }

    /**
     * @notice check if transaction index valid
     */
    function _isIndexValid(uint256 _transactionIndex) internal view{
        if(_transactionIndex >= transactionList.length){
            revert InvalidTransactionIndex();
        }
    }

    /************************
     *   Recovery functions
     ************************/
    /**
     * @notice guardian submit recovery
     * @param _replacedOwner owner to be replaced
     * @param _newOwner address of new owner
     */
    function submitRecovery(
        address _replacedOwner,
        address _newOwner
    )
        external
        onlyGuardian
    {
        if(msg.sender == address(entryPointErc4337)){
            _submitRecovery(_replacedOwner, _newOwner, signedByGuardian);
            resetSignedByGuardian();
        } else {
            _submitRecovery(_replacedOwner, _newOwner, msg.sender);
        }
    }

    function _submitRecovery(
        address _replacedOwner,
        address _newOwner,
        address _proposer
    )
        internal
    {
        if(isRecovering){
            revert WalletIsRecovering();
        }

        if(_newOwner == address(0)){
            revert InvalidAddress();
        }

        if(owners.contains(_newOwner)){
            revert AlreadyAnOwner(_newOwner);
        }

        if(!owners.contains(_replacedOwner)){
            revert NotOwner();
        }

        isRecovering = true;
        recoveryProposed.replacedOwner = _replacedOwner;
        recoveryProposed.newOwner = _newOwner;
        recoveryProposed.supportNum = 0;

        emit SubmitRecovery(_replacedOwner, _newOwner, _proposer);
    }

    /**
     * @notice guardian support recovery
     */
    function supportRecovery() public onlyGuardian{
        if(msg.sender == address(entryPointErc4337)){
            _supportRecovery(signedByGuardian);
            resetSignedByGuardian();
        } else {
            _supportRecovery(msg.sender);
        }
    }

    function _supportRecovery(address _supporter) internal {
        if(!isRecovering){
            revert WalletIsNotRecovering();
        }

        if(recoverBy[recoverRound][_supporter]){
            revert AlreadyRecoverBy(_supporter);
        }

        recoverBy[recoverRound][_supporter] = true;
        ++recoveryProposed.supportNum;
    }

    /**
     * @notice execute recovery
     * @dev only owner can execute recovery after support num >= recoverThreshold
     */
    function executeRecovery() public onlyOwner {
        if(msg.sender == address(entryPointErc4337)){
            _executeRecovery();
            resetSignedByOwner();
        } else {
            _executeRecovery();
        }
    }

    function _executeRecovery() internal {
        if(!isRecovering){
            revert WalletIsNotRecovering();
        }

        if(recoveryProposed.supportNum < recoverThreshold){
            revert SupportNumNotEnough();
        }

        // change owner
        address oldOwner = recoveryProposed.replacedOwner;
        address newOwner = recoveryProposed.newOwner;
        owners.remove(oldOwner);
        owners.add(newOwner);

        // initial for next time
        isRecovering = false;
        ++recoverRound;
        delete recoveryProposed;

        emit ExecuteRecovery(oldOwner, newOwner);
    }

    /**
     * @notice get Recovery informations
     */
    function getRecoveryInfo() external view 
        returns(
            address, 
            address, 
            uint256
        )
    {
        return (
            recoveryProposed.replacedOwner,
            recoveryProposed.newOwner,
            recoveryProposed.supportNum
        );
    }

    /************************
     *   Freeze functions
     ************************/

    /**
     * @notice freeze wallet
     */
    function freezeWallet() external onlyOwner {
        if(msg.sender == address(entryPointErc4337)){
            _freezeWallet();
            resetSignedByOwner();
        } else {
            _freezeWallet();
        }
    }

    function _freezeWallet() internal {
        isFreezing = true;

        emit FreezeWallet();
    }

    /**
     * @notice unfreeze wallet
     * @dev the wallet will not unfreeze until unfreezeCounter >= leastConfirmThreshold
     */
    function unfreezeWallet() external onlyOwner {
        if(msg.sender == address(entryPointErc4337)){
            _unfreezeWallet(signedByOwner);
            resetSignedByOwner();
        } else {
            _unfreezeWallet(msg.sender);
        }
    }

    function _unfreezeWallet(address _owner) internal {
        if(!isFreezing){
            revert WalletIsNotFrozen();
        }

        if(unfreezeBy[unfreezeRound][_owner]){
            revert AlreadyUnfreezeBy(_owner);
        }

        unfreezeBy[unfreezeRound][_owner] = true;
        if(++unfreezeCounter >= leastConfirmThreshold){
            isFreezing = false;
            // start a new round for the next time
            ++unfreezeRound;
            unfreezeCounter = 0;

            emit UnfreezeWallet();
        }
    }

    /************************
     *   Argument functions
     ************************/
    
    /**
     * @notice add a new address to whiteList
     * @param _whiteAddr address to be added
     * @dev only execute by executeTransaction, which means pass the multisig
     */
    function addWhiteList(address _whiteAddr) external onlyExecuteByWallet{
        _addWhiteList(_whiteAddr);
    }

    function _addWhiteList(address _whiteAddr) internal {
        // address(0) and wallet cannot on the whiteList
        // if wallet is on the whiteList, arguments can be modified by only one confirmation
        if(
            _whiteAddr == address(this) ||
            _whiteAddr == address(0)
        ){
            revert InvalidAddress();
        }

        if(!whiteList.add(_whiteAddr)){
            revert AlreadyOnWhiteList(_whiteAddr);
        }

        emit AddNewWhiteList(_whiteAddr);
    }
    
    /**
     * @notice remove address from whiteList
     * @param _removeAddr address to be removed
     * @dev only execute by executeTransaction, which means pass the multisig
     */
    function removeWhiteList(address _removeAddr) external onlyExecuteByWallet{
        _removeWhiteList(_removeAddr);
    }

    function _removeWhiteList(address _removeAddr) internal {
        if(!whiteList.remove(_removeAddr)){
            revert NotOnWhiteList();
        }

        emit RemoveWhiteList(_removeAddr);
    }

    /**
     * @notice replace guardian
     * @param _oldGuardianHash hash of old guardian's address
     * @param _newGuardianHash hash of new guardian's address
     * @dev only execute by executeTransaction, which means pass the multisig
     */
    function replaceGuardian(bytes32 _oldGuardianHash, bytes32 _newGuardianHash) external onlyExecuteByWallet{
        // cannot replace a guardian while recovering
        if(isRecovering){
            revert WalletIsRecovering();
        }

        if(!guardianHashes.remove(_oldGuardianHash)){
            revert NotGuardian();
        }

        if(!guardianHashes.add(_newGuardianHash)){
            revert AlreadyAGuardian(_newGuardianHash);
        }

        emit ReplaceGuardian(_oldGuardianHash, _newGuardianHash);
    }

    function isOwner(address _addr) external view returns(bool) {
        return owners.contains(_addr);
    }

    function isGuardian(bytes32 _hash) external view returns(bool) {
        return guardianHashes.contains(_hash);
    }

    function isWhiteList(address _addr) external view returns(bool){
        return whiteList.contains(_addr);
    }

    function resetSignedByOwner() internal {
        signedByOwner = address(0);
    }

    function resetSignedByGuardian() internal {
        signedByGuardian = address(0);
    }

    /************************
     *   Receive Tokens
     ************************/
    /**
     * @notice IERC721Receiver
     */
    function onERC721Received(address, address, uint256, bytes memory) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @notice IERC1155Receiver
     */
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @notice IERC1155Receiver
     */
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) 
        external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Support for EIP 165
     */
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        if (
            _interfaceId == 0x01ffc9a7 || // ERC165 interfaceID
            _interfaceId == 0x150b7a02 || // ERC721TokenReceiver interfaceID
            _interfaceId == 0x4e2312e0 // ERC1155TokenReceiver interfaceID
        ) {
            return true;
        }
        return false;
    }

    /************************
     *   UUPS upgrade
     ************************/
    function upgradeTo(address _newImpl) external onlyExecuteByWallet{
        updateCodeAddress(_newImpl);
    }

    function upgradeToAndCall(address _newImpl, bytes memory _data) external onlyExecuteByWallet{
        updateCodeAddress(_newImpl);
        (bool success,) = _newImpl.delegatecall(_data);
        require(success, "delegatecall failed");
    }

    /************************
     *   ERC-4337
     ************************/
    function entryPoint() public view virtual override returns (IEntryPoint){
        return entryPointErc4337;
    }

    /**
     * @notice validate signature of userOp
     * @dev return value is composed of validAfter, validUntil, aggregator
     * @dev just check pass or not and unlimited timestamp
     *       [ 6 bytes   +   6 bytes  +   20 bytes ]
     *       [validAfter + validUntil +  aggregator]
     *       if aggregator = 0 : pass validate
     *                     = 1 : fail validate
     *                     = address : agregator address
     *       validUntil : 6-byte timestamp value, or zero for “infinite”. 
     *       validAfter : 6-byte timestamp. The UserOp is valid only after this time.
     */
    function _validateSignature(
        UserOperation calldata _userOp,
        bytes32 _userOpHash
    )
        internal
        override
        returns (uint256) 
    {
        _getUserOperationSigner(_userOp, _userOpHash);
        bytes32 ethSignedMessageHash = _userOpHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(_userOp.signature);

        // signed by owner
        if (owners.contains(signer)){
            signedByOwner = signer;
            return 0;
        }

        // signed by guardian
        if (guardianHashes.contains(keccak256(abi.encodePacked(signer)))){
            signedByGuardian = signer;
            return 0;
        }
        
        return SIG_VALIDATION_FAILED;
    }

    function _validateNonce(uint256 _nonce) internal view override virtual {
        require(_nonce < type(uint64).max);
    }

    function _getUserOperationSigner(
        UserOperation calldata _userOp,
        bytes32 _userOpHash
    ) 
        internal
        pure
        returns(address signer)
    {
        bytes32 ethSignedMessageHash = _userOpHash.toEthSignedMessageHash();
        signer = ethSignedMessageHash.recover(_userOp.signature);
    }

}