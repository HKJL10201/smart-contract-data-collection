pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
// Based on: https://solidity-by-example.org/app/multi-sig-wallet/
// But with a social recovery scheme

import "hardhat/console.sol";

contract YourContract {
    enum UpdateType {
      Guardian,
      Confirmation,
      Transaction,
      Recovery
    }

    struct Update {
      bool executed;
      uint numConfirmations;
      UpdateType typ;
    }

    struct GuardianInfo {
      address guardian;
    }
    struct ConfirmationInfo {
      uint newTxnConfirmationThreshold;
    }
    struct TransactionInfo {
      address to;
      uint value;
    }
    struct RecoveryInfo {
      address newOwner;
      uint256 endTime;
    }

    event UpdateAdded(uint256 updateIdx, UpdateType typ);
    event ConfirmationAdded(address guardian, uint256 updateIdx);

    // mapping from tx index => guardian => bool
    mapping(uint => mapping(address => bool)) public isConfirmedUpdate;
    Update[] public updates;
    // mapping from tx index => infos of various types
    mapping (uint => GuardianInfo) public addGuardianInfo;
    mapping (uint => ConfirmationInfo) public changeConfirmationInfo;
    mapping (uint => TransactionInfo) public transactionInfo;
    mapping (uint => RecoveryInfo) public recoveryInfo;

    address[] public guardians;
    mapping(address => bool) public isGuardian;
    uint public guardianMajority;
    address public owner;
    uint public txnConfirmationThreshold;

    modifier onlyOwner() {
        require(msg.sender == owner, "must be owner");
        _;
    }

    modifier onlyGuardian() {
        require(checkIsGuardian(msg.sender), "must be a guardian");
        _;
    }

    function checkIsGuardian(address _maybeGuardian) public view returns (bool) {
      return isGuardian[_maybeGuardian];
    }

    modifier updateExists(uint _updateIdx) {
        require(_updateIdx < updates.length, "update does not exist");
        _;
    }

    modifier updateNotExecuted(uint _updateIdx) {
        require(!updates[_updateIdx].executed, "update already executed");
        _;
    }

    modifier updateNotConfirmed(uint _updateIdx) {
        require(!isConfirmedUpdate[_updateIdx][msg.sender], "update already confirmed by sender");
        _;
    }

    modifier updateConfirmed(uint _updateIdx) {
        require(isConfirmedUpdate[_updateIdx][msg.sender], "update has not been confirmed");
        _;
    }

    modifier canExecuteUpdate(uint _updateIdx) {
        require(msg.sender == owner, "must be owner");
        require(_updateIdx < updates.length, "update does not exist");
        require(!updates[_updateIdx].executed, "update already executed");
        _;
    }

    modifier canExecuteRecovery(uint _updateIdx) {
        require(isGuardian[msg.sender], "must be a guardian to execute recovery");
        require(_updateIdx < updates.length, "update does not exist");
        require(!updates[_updateIdx].executed, "update already executed");
        _;
    }

    constructor(address _owner, address, uint256 _thresholdInEth) public {
        require(_owner != address(0), "owner cannot be 0 address");
        // even though there are 0 guardians, set the majority to 1
        // to force the addition of the first guardian
        guardianMajority = 1;
        txnConfirmationThreshold = _thresholdInEth * 1e18;
        owner = _owner;
    }

    function addFirstGuardian(address _guardian) external onlyOwner {
        require(_guardian != address(0), "guardian cannot be 0 address");
        require(_guardian != owner, "guardian cannot be owner");
        require(guardians.length == 0, "there cannot be ANY existing guardians");
        isGuardian[_guardian] = true;
        guardians.push(_guardian);
    }

    function addGuardian(address _guardian) internal {
        require(_guardian != address(0), "guardian cannot be 0 address");
        require(_guardian != owner, "guardian cannot be owner");
        require(!checkIsGuardian(_guardian), "guardian already exists");
        isGuardian[_guardian] = true;
        guardians.push(_guardian);
        guardianMajority = guardians.length / 2;
    }

    receive() payable external {
        //emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function tryImmediateTxn(address _to, uint _value) public onlyOwner {
      require(_value <= txnConfirmationThreshold, "amount to transfer must be less than or equal to transferLimit");
      // TODO: Probably a check to ensure _value isn't negative && the _to address is legit
      require(_value <= address(this).balance, "not enough funds");

      (bool success, ) = _to.call{value: _value}("");
      require(success, "txn failed");
    }

    function submitLongTxn(address _to, uint _value) public onlyOwner {
      require(_value > txnConfirmationThreshold, "submit an immediate txn instead");
      // TODO: Probably a check to ensure _value isn't negative && the _to address is legit
      require(_value <= address(this).balance, "not enough funds");
      transactionInfo[updates.length] = TransactionInfo({
        to: _to,
        value: _value
      });
      addUpdate(UpdateType.Transaction);
    }
    
    function submitThresholdChange(uint _newThreshold) public onlyOwner {
      require(_newThreshold != txnConfirmationThreshold, "new threshold must be different");
      changeConfirmationInfo[updates.length] = ConfirmationInfo({
        newTxnConfirmationThreshold: _newThreshold
      });
      addUpdate(UpdateType.Confirmation);
    }
    
    function submitGuardianAdd(address _newGuardian) public onlyOwner {
      require(!checkIsGuardian(_newGuardian), "guardian already exists");
      require(_newGuardian != owner, "guardian cannot be owner");
      addGuardianInfo[updates.length] = GuardianInfo({
        guardian: _newGuardian
      });
      addUpdate(UpdateType.Guardian);
    }

    function submitRecovery(address _newOwner) public onlyGuardian {
      require(owner != _newOwner, "new owner must be different");
      require(_newOwner != address(0), "new owner cannot be null address");
      recoveryInfo[updates.length] = RecoveryInfo({
          newOwner: _newOwner,
          // expires in 10000 seconds
          endTime: now + 10000
      });
      addUpdate(UpdateType.Recovery);
    }

    function addUpdate(UpdateType typ) internal {
      updates.push(Update({
        executed: false,
        numConfirmations: 0,
        typ: typ
      }));
      emit UpdateAdded(updates.length - 1, typ);
    }

    function confirmUpdate(uint _updateIdx)
      public
      onlyGuardian
      updateExists(_updateIdx)
      updateNotExecuted(_updateIdx)
      updateNotConfirmed(_updateIdx)
    {
      Update storage update = updates[_updateIdx];
      update.numConfirmations += 1;
      isConfirmedUpdate[_updateIdx][msg.sender] = true;

      RecoveryInfo memory r = recoveryInfo[_updateIdx];
      if (r.endTime != 0) {
        require(now < r.endTime, "time to confirm ownership change has expired");
      }

      emit ConfirmationAdded(msg.sender, _updateIdx);
    }

    function revokeConfirmation(uint _updateIdx)
      public
      onlyGuardian
      updateExists(_updateIdx)
      updateNotExecuted(_updateIdx)
      updateConfirmed(_updateIdx)
    {
      Update storage update = updates[_updateIdx];
      update.numConfirmations -= 1;
      isConfirmedUpdate[_updateIdx][msg.sender] = false;
    }


    function executeLongTxn(uint _updateIdx)
      public
      canExecuteUpdate(_updateIdx)
    {
      preExecuteUpdate(_updateIdx);
      TransactionInfo memory t = transactionInfo[_updateIdx];
      (bool success, ) = t.to.call{value: t.value}("");
      require(success, "tx failed");
    }

    function executeConfirmationChange(uint _updateIdx)
      public
      canExecuteUpdate(_updateIdx)
    {
      preExecuteUpdate(_updateIdx);
      ConfirmationInfo memory c = changeConfirmationInfo[_updateIdx];
      txnConfirmationThreshold = c.newTxnConfirmationThreshold;
    }

    function executeGuardianAdd(uint _updateIdx)
      public
      canExecuteUpdate(_updateIdx)
    {
      preExecuteUpdate(_updateIdx);
      GuardianInfo storage g = addGuardianInfo[_updateIdx];
      addGuardian(g.guardian);
    }

    function executeRecovery(uint _updateIdx)
      public
      canExecuteRecovery(_updateIdx)
    {
      preExecuteUpdate(_updateIdx);
      RecoveryInfo memory r = recoveryInfo[_updateIdx];
      owner = r.newOwner;
    }

    function preExecuteUpdate(uint _updateIdx) internal {
      Update storage u = updates[_updateIdx];
      require(u.numConfirmations >= guardianMajority, "not enough guardians");
      u.executed = true;

      RecoveryInfo memory r = recoveryInfo[_updateIdx];
      if (r.endTime != 0) {
        require(now < r.endTime, "time to confirm ownership change has expired");
      }
    }

    function getGuardians() public view returns (address[] memory) {
        return guardians;
    }
}