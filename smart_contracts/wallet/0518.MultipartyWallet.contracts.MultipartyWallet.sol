//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MultipartyWallet {
  address public admin;
  mapping(address =>  bool) public owners;
  uint public quorum;
  uint public ownerCount;

  struct Transaction {
    address createdBy;
    uint id;
    uint approvalsReceived;
    uint approvalsRequired;
    bool cleared;
  }
  mapping(uint => Transaction) public transactions;
  uint public nextId;

  constructor(uint _quorum) payable {
    admin = msg.sender;
    quorum = _quorum;    
  }

  event OwenrAdded(address owner); 
  event OwenrRemoved(address owner);
  event TransactionCreated(uint transid, address owner);
  event TransactionExecuted(uint transid, address owner);

  function addOwner(address _owner)  onlyAdmin() external returns (bool) {
    require(owners[_owner] == false, "Already Added");
      owners[_owner] = true;
      ownerCount = ownerCount+1;
      emit OwenrAdded(_owner);
      return true;
   }

  function removeOwner(address _owner)  onlyAdmin() external returns (bool) {
   require(owners[_owner] == true, "not a owner address");
      owners[_owner] = false;
      ownerCount = ownerCount-1;
      emit OwenrRemoved(_owner);      
      return true;
   }

   function updateQuorum(uint _quorum)  onlyAdmin() external {
       quorum = _quorum;
   }

   function updateTransactionQuorum(uint _transId, uint _quorum)  onlyAdmin() external {
       transactions[_transId].approvalsRequired = (ownerCount*_quorum)/100;
   }

   function getTransactionApprovalsRequired(uint _transId)  external view returns(uint transTotalQuorum){
       return transactions[_transId].approvalsRequired;
   }

   function getTransactionApprovalsReceived(uint _transId)  external view returns(uint transTotalQuorum){
       return transactions[_transId].approvalsReceived;
   }

   function getTransactionStatus(uint _transId)  external view returns(bool status){
       return transactions[_transId].cleared;
   }

  function createTransaction() onlyApprover() external {
    transactions[nextId] = Transaction(msg.sender, nextId, 0, (ownerCount*quorum)/100, false);
    nextId++;
    emit TransactionCreated(nextId-1,msg.sender);
  }

  function approveTransaction(uint id) onlyApprover() external {
      require(transactions[id].cleared == false, "Transaction has been already cleared");
      require(transactions[id].createdBy != msg.sender, "Creater of transaction cannot approve");
      transactions[id].approvalsReceived++;
  }

    function  executeTransaction(uint id) external {
      require(transactions[id].cleared == false, "Transaction has been already cleared");
      require(transactions[id].createdBy == msg.sender, "Only Owner of transction can execute");
      require(transactions[id].approvalsReceived >= transactions[id].approvalsRequired, "quorum has not reached");
      transactions[id].cleared = true;
      emit TransactionExecuted(id,msg.sender);
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "only Admin");
    _;  
  }
  modifier onlyApprover() {
    require(owners[msg.sender] == true, "only Approvers");
    _;  
  }
}