pragma solidity ^0.4.21;

import "./WalletLibrary.sol";

contract ResidualEMMonitor {

    function exitInitWallet(){
        if(currentState == 0){
            currentState = 1;
        }
        else{
            revert();
        }
    }
    
    function exitExecute(){
      if(currentState == 0){
          revert();
      }
    }
    
    function exitSendEther(){
        if(currentState == 0){
            revert();
        }
    }
    
    
      // FIELDS
  address constant _walletLibrary = 0xcafecafecafecafecafecafecafecafecafecafe;

  // the number of owners that must confirm the same operation before it is run.
  uint public m_required;
  // pointer used to find a free slot in m_owners
  uint public m_numOwners;

  uint public m_dailyLimit;
  uint public m_spentToday;
  uint public m_lastDay;

  // list of owners
  uint[256] m_owners;

  uint constant c_maxOwners = 250;
  // index on the list of owners to allow reverse lookup
  mapping(uint => uint) m_ownerIndex;
  // the ongoing operations.
  mapping(bytes32 => WalletLibrary.PendingState) m_pending;
  bytes32[] m_pendingIndex;

  // pending transactions we have at present.
  mapping (bytes32 => WalletLibrary.Transaction) m_txs;
  
  mapping (address => address[]) userToMonitor;
 
  //monitoring state
  int currentState = 0;
}
