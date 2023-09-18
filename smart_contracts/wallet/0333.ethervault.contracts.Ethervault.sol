pragma solidity ^0.8.16;
// SPDX-License-Identifier:MIT
/*

 888~~    d8   888                       Y88b      /                    888   d8
 888___ _d88__ 888-~88e  e88~~8e  888-~\  Y88b    /    /~~~8e  888  888 888 _d88__
 888     888   888  888 d888  88b 888      Y88b  /         88b 888  888 888  888
 888     888   888  888 8888__888 888       Y888/     e88~-888 888  888 888  888
 888     888   888  888 Y888    , 888        Y8/     C888  888 888  888 888  888
 888___  "88_/ 888  888  "88___/  888         Y       "88_-888 "88_-888 888  "88_/
a lightweight, gas effecient, multisignature wallet ~ Darkerego, Copyright 2023
*/


//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EtherVault {

    /*
      @dev: gas optimized variable packing
    */

    bool public paused;
    uint8 public version = 1;
    uint8 private mutex;
    uint8 public signerCount;
    uint8 public threshold;
    uint16 public proposalId;
    uint32 public execNonce;
    uint32 public txCount;
    uint32 private lastDay;
    uint128 public dailyLimit;
    uint128 public spentToday;


    struct Proposal{
        address proposer;
        address modifiedSigner;
        uint8 newThreshold;
        uint8 numSigners;
        uint32 initiated;
        uint128 newLimit;
        bool paused;
        mapping (address => uint8) approvals;
    }

    struct Transaction{
        address dest;
        uint128 value;
        bytes data;
        uint8 numSigners;
        mapping (address => uint8) approvals;
    }

    /*
      @dev: Error codes:
      This is cheaper than using require statements or strings.
      Tried using bytes, but no good way to convert them to strings,
      so that leaves unsigned ints as error codes.
    */
    bytes2 constant authError = "03";
    bytes2 constant proposalError = "12";
    bytes2 constant txError = "05";
    bytes2 constant pausedError = "08";
    error FailAndRevert(bytes2);

    /*
      @dev: Error Codes are loosely modeled after HTTP error codes. Their definitions are
      here and in the documentation:

      03 -- Restricted Function Errors
          -- Access denied for caller attempting to access protected function (caller is not a signer)
          -- Access denied because state is Locked (blocked attempted reentrancy)
      04 -- Transaction Errors
          -- Cannot execute because transaction not found (either already executed or invalid txid)
          -- Insufficient balance for request
      06 -- Nonce Error
      08 -- Contract is paused
      12 Signature Errors
         -- Cannot add signer because address already is a signer
         -- Cannot sign, no proposal Found
         -- Cannot revoke because address is not a signer
         -- Cannot sign because caller already signed
         -- Cannot propose, proposal already pending

    */

    /*
      @dev: Mapping Indexes
       Signer address => 1 (substituted for bool to save gas)
       TXID > Transaction
       ProposalID => Proposal
    */
    mapping (address => uint8) isSigner;
    mapping (uint32 => Transaction) public pendingTxs;
    mapping (uint16 => Proposal) public pendingProposals;
    //token address > chainlink price feed address
    //mapping (address => address) priceFeeds;

    function auth(address s, uint32 _nonce) private {
        /*
          @dev: Checks if sender is a signer, checks nonce,
          and ensures system state is not locked.
        */
        if( isSigner[s] == 0 ||_nonce <= execNonce || _nonce > execNonce+1 || mutex == 1){
            revert FailAndRevert(authError);
       } // increment nonce if all checks pass
       execNonce += 1;
    }

    function revertWhenPaused() private {
        if (paused) {
            revert FailAndRevert(pausedError);
        }
    }

    modifier protected(uint32 _nonce) {
        /*
          @dev: Restricted function access protection and reentrancy guards.
          Saves some gas by combining these checks and using an int instead of
          bool.
        */
       auth(msg.sender, _nonce);
       mutex = 1;
       _;
       mutex = 0;

    }

    constructor(
        address[] memory _signers,
        uint8 _threshold,
        uint128 _dailyLimit
        //address ethPriceFeedAddress
        ){
            /*
              @dev: When I wrote this, I never imagined having more than 128
              signers. If for some reason you do, you may want to modify this code.
            */

        unchecked{ // save some gas
        uint8 slen = uint8(_signers.length);
        signerCount = slen;
        for (uint8 i = 0; i < slen; i++) {
            isSigner[_signers[i]] = 1;
        }
      }
        (threshold, dailyLimit, spentToday, mutex, paused) = (_threshold, _dailyLimit, 0, 0, false);

    }
    /*
       @dev: Allow arbitrary deposits to contract.
     */

    receive() external payable {}

    function execute(
        /*
            @dev: Function to execute a transaction with arbitrary parameters. Handles
            all withdrawals, etc. Can be used for token transfers, eth transfers,
            or anything else.
        */
        address recipient,
        uint256 _value,
        bytes memory data
        ) private {

       assembly {
            let success_ := call(gas(), recipient, _value, add(data, 0x20), mload(data), 0x0, 0x0)
            let success := eq(success_, 0x1)
            let retSz := returndatasize()

            if iszero(success) {
                revert(data, retSz)}
            }
        }

    function sign(uint32 txid, uint16 _proposalId, address signer) private {
        /*
          @dev: Function to sign transactions and proposals.
        */
        if (txid == 0) {
            pendingProposals[_proposalId].approvals[signer] = 1;
            pendingProposals[_proposalId].numSigners += 1;
        } else {
            pendingTxs[txid].approvals[signer] = 1;
            pendingTxs[txid].numSigners += 1;
        }
    }

    function newProposal(
        /*
          @dev: Create a new proposal to change the daily limits, the signer threshold, or to
          add or revoke a signer. If the specified address is already a signer, then this is a
          revokation change. If not, it is a granting change.
        */
        address _signer,
        uint128 _limit,
        uint8 _threshold,
        bool _paused,
        uint32 _nonce
    ) external protected(_nonce) returns(uint16){
        proposalId += 1;
        Proposal storage prop = pendingProposals[proposalId];
        (prop.modifiedSigner, prop.newLimit, prop.initiated,
        prop.newThreshold, prop.proposer) = (_signer, _limit,
        uint32(block.timestamp),  _threshold, msg.sender);
        prop.paused = _paused;
        sign(0, proposalId, msg.sender);
        return proposalId;
    }

    function deleteProposal(uint16 _proposalId, uint32 _nonce) external protected(_nonce) {
        /*
          @dev: Allow only the proposer to delete a pending proposal they created.
        */
        Proposal storage proposalObj = pendingProposals[_proposalId];
        if (proposalObj.proposer == msg.sender){
            delete pendingProposals[_proposalId];
        }
    }

    function approveProposal(uint16 _proposalId,  uint32 _nonce) external protected(_nonce) {
        /*
          @dev: Approve a pending proposal.
        */
         if (pendingProposals[proposalId].approvals[msg.sender] == 1){
            revert FailAndRevert(proposalError);
        }
        Proposal storage proposalObj = pendingProposals[_proposalId];

        // if all signers have signed
        if(proposalObj.numSigners +1 == signerCount)  {
             // if limit/threshold are being updated
            if (proposalObj.newLimit > 0||proposalObj.newThreshold >0){

                dailyLimit = proposalObj.newLimit;
                threshold = proposalObj.newThreshold;
            }
            // if updating signers
            if (proposalObj.modifiedSigner != address(0)) {
                if (isSigner[proposalObj.modifiedSigner] == 1) {
                    /*
                    @dev: Signer exists, so this must be a revokation proposal.
                    revoke this signer and reset the approval count.
                    Admin cannot be revoked.
                    */
                    isSigner[proposalObj.modifiedSigner] = 0;
                    signerCount-=1;

                } else {
                    /*
                    @dev: Signer does not exist yet, so this must be signer addition.
                    Grant signer role, reset pending signer count.
                    */
                    isSigner[proposalObj.modifiedSigner] = 1;
                    signerCount+=1;
            }
            }
            delete pendingProposals[_proposalId];
        } else {
            // More signatures needed, so just sign.
            //signProposal(msg.sender, _proposalId);
            sign(0, _proposalId, msg.sender);
        }
    }

    function deleteTx(
        /*
          @dev: Remove pending transaction from storage and cancel it.
        */
        uint32 txid,
        uint32 _nonce
        ) external protected(_nonce) {
        revertWhenPaused();
        if (pendingTxs[txid].dest == address(0)) {
            revert FailAndRevert(txError);
        }
        delete pendingTxs[txid];
    }


    function approveTx(
        /*
          @dev: Function to approve a pending tx. If the signature threshold
          is met, the transaction will be executed in this same call. Reverts
          if the caller is the same signer that initialized or already approved
          the transaction.
        */
        uint32 txid,
        uint32 _nonce
        ) external protected(_nonce) {
        revertWhenPaused();
        Transaction storage _tx = pendingTxs[txid];
       if (_tx.dest == address(0)){
                revert FailAndRevert(txError); // tx does not exist
            }
       if (pendingTxs[txid].approvals[msg.sender] == 0){
            if(_tx.numSigners + 1 >= threshold){
                execute(_tx.dest, _tx.value, _tx.data);
                delete pendingTxs[txid];
            } else {
                sign(txid, 0, msg.sender);
            }

        } else {
            revert FailAndRevert(txError);
        }
    }



    function submitTx(
        /*
          @dev: Initiate a new transaction. Logic flow:
          (Note: to save gas, the nonce also doubles as the TXID.)
           1) First, check the "nonce"
           2) Next, check that we have balance to cover this transaction.
           3) Check if requested ethere value (in wei) is below our daily
           allowance:
             yes) The transaction will be executed here and value added to `spentToday`.
             no)  The transaction requires the approval of `threshold` signatories,
                  so it will be queued pending approval.
        */
        address recipient,
        uint128 value,
        bytes memory data,
        uint32 _nonce

        ) external payable protected(_nonce) returns(uint32) {
        revertWhenPaused();
        // gas effecient balance call
        uint128 self;
        assembly {
            self :=selfbalance()
        }
        // make sure we have equity for this request
        if(self < value){
            revert FailAndRevert(txError);
        }

        if (underLimit(value)) {
            // limit not reached, no further authorization required.
            spentToday += value;
            execute(recipient, value, data);
        } else {
            txCount += 1;
            // requires approval from signatories -- not factored into daily allowance
            Transaction storage txObject = pendingTxs[txCount];
            (txObject.dest, txObject.value, txObject.data) = (recipient, value, data);
            sign(txCount, 0, msg.sender);
        }
        return txCount;

    }

    function underLimit(uint128 _value) private returns (bool) {
        /*
          @dev: Function to determine whether or not a requested
          transaction's value is over the daily allowance and
          shall require additional confirmation or not. If it is
          a different day from the last time this ran, reset the
          allowance.
        */
        uint32 t = uint32(block.timestamp / 1 days);
        if (t > lastDay) {
            (spentToday, lastDay) = (0,t);
        }
        // check to see if there's enough left
        if (spentToday + _value <= dailyLimit) {
            return true;
        }
            return false;
    }

}

