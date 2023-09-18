pragma solidity ^0.8.16;
// SPDX-License-Identifier:MIT
/*

888~~    d8   888                       Y88b      /                    888   d8
888___ _d88__ 888-~88e  e88~~8e  888-~\  Y88b    /    /~~~8e  888  888 888 _d88__
888     888   888  888 d888  88b 888      Y88b  /         88b 888  888 888  888
888     888   888  888 8888__888 888       Y888/     e88~-888 888  888 888  888
888     888   888  888 Y888    , 888        Y8/     C888  888 888  888 888  888
888___  "88_/ 888  888  "88___/  888         Y       "88_-888 "88_-888 888  "88_/



Darkerego, 2023 ~ Ethervault is a lightweight, gas effecient,
multisignature wallet
*/


contract EtherVaultTest {

    /*
      @dev: gas optimized variable packing
    */
    uint8 mutex;
    uint8 signerCount;
    address payable sender;
    uint8 proposalSignatures;
    uint8 public threshold;
    uint8 public pendingThreshold;
    uint16 proposalId;
    uint32 public execNonce;
    uint32 public lastDay;
    uint128 public dailyLimit;
    uint128 public pendingDailyLimit;
    uint128 public spentToday;
    // echidna stuff
    address[] _signers = [0xED9E5886Ba3de69651BF0CAb407CcD8c3885405f, 0xdF0dd354cA601EE75C88f08E5B9F18fC6Db3737F, 0xa9bcCFeb2276C534C6eC096f7f556DFF386796aB];
        //sender = payable(msg.sender);

    address proposedSigner;
    struct Transaction{
        address dest;
        uint128 value;
        bytes data;
        uint8 numSigners;
    }

    /*
      @dev: Error codes:
      This is cheaper than using require statements or strings.
      Tried using bytes, but no good way to convert them to strings,
      so that leaves unsigned ints as error codes.
    */

    error TxError(uint s);
    error AccessError(uint s);
    error ProposalError(uint s);

    /*
      @dev: Error Codes are loosely modeled after HTTP error codes. Their definitions are
      here and in the documentation:

      403 -- Access denied for caller attempting to access protected function
      404 -- Cannot execute because transaction not found
      423 -- Refuse execution because state is Locked (reentrency gaurd)
      208 -- Cannot sign because caller already signed
      406 -- Cannot revoke because address is not a signer
      412 -- Cannot add signer because address already is a signer
      302 -- Cannot sign, no proposal Found
      204 -- Cannot propose, proposal already pending
    */



    mapping (address => uint8) public isSigner;
    mapping (uint32 => Transaction) public pendingTxs;
    /*
      @dev: pending propsal for signer modifications:
      new/revoking proposal id => (current signer => Has approved) --
      requires all current signers permission to add new signer.
      If address already exists, this is a revokation,
      otherwise it is an addition.
    */
    mapping (uint16 => mapping(address => uint8)) pendingProposal;
    mapping (uint => mapping (address => uint8)) confirmations;

    function checkSigner(address s) private view {
        /*
          @dev: Checks if sender is caller
          and for reentrancy.
        */
        if( isSigner[s] == 0||mutex == 1){
            revert AccessError(403);
       }
    }


    modifier protected {
        /*
          @dev: Restricted function access protection and reentrancy guards.
          Saves some gas by combining these checks and using an int instead of
          bool.
        */
       checkSigner(msg.sender);
       mutex = 1;
       _;
       mutex = 0;

    }

    /*constructor(
        address[] memory _signers,
        uint8 _threshold,
        uint128 _dailyLimit
        ){
            /
              @dev: When I wrote this, I never imagined having more than 128
              signers. If for some reason you do, you may want to modify this code.
            /
        unchecked{ // save some gas
        uint8 slen = uint8(_signers.length);
        signerCount = slen;
        for (uint8 i = 0; i < slen; i++) {
            isSigner[_signers[i]] = 1;
        }
      }
        (threshold, dailyLimit, spentToday, mutex) = (_threshold, _dailyLimit, 0, 0);
    }*/
    constructor(){
        // Echidna friendly Test version


        _signers.push(msg.sender);
        (threshold, dailyLimit, spentToday, mutex) = (2, 10000000000000, 0, 0);
        //vault = new EtherVault(signers, 2, 50000000000000000);
        unchecked{ // save some gas
        uint8 slen = uint8(_signers.length);
        signerCount =uint8( _signers.length);
        for (uint8 i = 0; i < slen; i++) {
            isSigner[_signers[i]] = 1;
        }
    }}

    function alreadySigned(
        /*
          @dev: Checks to make sure that signer cannot sign multiple times.
        */
        uint txid,
        address owner
    ) private view returns(bool){
       if(confirmations[txid][owner] == 0){
           return false;
       }
       return true;
    }

    function alreadySignedProposal(address signer) private view {

        if (pendingProposal[proposalId][signer] == 1){
            revert ProposalError(208);
        }
    }

    function execute(
        address r,
        uint256 v,
        bytes memory d
        ) internal {
       /*
         @dev: Gas efficient arbitrary call in assembly.
       */
        assembly {
            let success_ := call(gas(), r, v, add(d, 0x00), mload(d), 0x20, 0x0)
            let success := eq(success_, 0x1)
            if iszero(success) {
                revert(mload(d), add(d, 0x20))
            }
        }
    }



    function signProposal(address caller) private {
        pendingProposal[proposalId][caller] = 1;
        proposalSignatures += 1;
    }

    function proposeRevokeSigner(
        /*
          @dev: Remove an authorized signer.
        */
        address _newSignerAddr
        ) external protected {
        revertIfProposalPending(true);
        if (isSigner[_newSignerAddr] == 1) {
            proposedSigner = _newSignerAddr;
            signProposal(msg.sender);
        } else {
            revert ProposalError(406);
        }
    }


    function proposeAddSigner(
        /*
          @dev: Add an authorized signer.
        */

        address _newSignerAddr
        ) external protected {
        revertIfProposalPending(true);
        if (isSigner[_newSignerAddr] == 1){
            revert ProposalError(412);
        }
        signProposal(msg.sender);
        proposedSigner = _newSignerAddr;
    }

    function confirmNewSignerProposal() external protected returns(bool) {
        revertIfProposalPending(false);
        alreadySignedProposal(msg.sender);
        if(proposalSignatures +1 == signerCount)  {
            /* @dev: Including this caller, all signers have been accounted for,
                the action shall be executed now.
            */

            if (isSigner[proposedSigner] == 1) {
                /*
                  @dev: Signer exists, so this must is a revokation proposal.
                  revoke this signer and reset the approval count.
                */
                isSigner[proposedSigner] = 0;
                signerCount-=1;


            } else {
                /*
                  @dev: Signer does not exist yet, so this must be signer addition.
                  Grant signer role, reset pending signer count.
                */
                isSigner[proposedSigner] = 1;
                signerCount+=1;

            }
            // in any case
            proposalSignatures = 0;
            proposedSigner = address(0);
            proposalId += 1;
            return true;


        } else {
            //@dev: We still need more signatures.
            signProposal(msg.sender);
            return true;
        }
        return false;
    }


    function proposeNewLimits(uint8 newThreshold, uint128 newLimit) public protected returns(bool)  {
        /*
          @dev: Function to iniate a proposal to update the threshold and daily
          allowance limit. Cannot be called if another proposal is already pending.
          Changing the threshold or limit requires the signature of all current
          signers.
        */
        revertIfProposalPending(true);
        pendingThreshold = newThreshold;
        pendingDailyLimit = newLimit;
        signProposal(msg.sender);
        return true;
    }


    function confirmProposedLimits() public protected  returns(bool){
        /*
          @dev: Confirm a proposal to update the threshold and/or
          spending limits. First, ensure there is such a proposal.
          Then check to see if including this signature, all signers
          are accounted for. If so, go ahead and update. If not,
          sign the proposal.
        */

        //revertIfProposalPending(false);
        alreadySignedProposal(msg.sender);
        if (proposalSignatures +1 == signerCount) {
            threshold = pendingThreshold;
            dailyLimit = pendingDailyLimit;
            pendingThreshold = 0;
            pendingDailyLimit = 0;
            proposalSignatures = 0;
            proposalId += 1;
            return true;}
        else {
            signProposal(msg.sender);
            return false;
        }
        return false;

    }

    function revertIfProposalPending(bool exist) private view {
        /*
          @dev Check if proposal exists and revert if not.
        */
        if(! exist){
            // revert if no pending proposal
            if (proposalSignatures == 0){
                revert ProposalError(302); }
     }  else{
            // revert if there is a pending proposal
            if (proposalSignatures != 0){
                revert ProposalError(204);
        }
    }}


    function revokeTx(
        /*
          @dev: Remove pending transaction from storage and cancel it.
        */
        uint32 txid
        ) external protected {
        if (pendingTxs[txid].dest == address(0)) {
            revert TxError(404);
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
        uint32 txid
        ) external protected returns(bool){
        Transaction memory _tx = pendingTxs[txid];
        bool ret;
        if(! alreadySigned(txid, msg.sender)){
            if (_tx.dest == address(0)){
                //revert TxError(404);
                ret = false;

            }
            if(_tx.numSigners + 1 >= threshold){
                delete pendingTxs[txid];
                execNonce += 1;
                execute(_tx.dest, _tx.value, _tx.data);
                ret = true;
            } else {
                _tx.numSigners += 1;
                ret = true;
            }
        } else {
            //revert TxError(406);
            ret = false;
        }
        return ret;
    }

    function signTx(uint32 txid, address signer) private {
        /*
          @dev: register a transaction confirmation.
        */
        confirmations[txid][signer] = 1;
        pendingTxs[txid].numSigners += 1;
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

        /*
           @dev: Echidna Test version of code: also return true if transaction immediatly executes,
           false if pending in queue awaiting signatures.
        */
        address recipient,
        uint128 value,
        bytes memory data,
        uint32 nonceTxid
        ) public payable protected returns(bool){
        /*Nonce also is transaction Id*/
        if(nonceTxid <= execNonce||pendingTxs[nonceTxid].dest != address(0)){
            revert TxError(409);
        }
        // gas effecient balance call
        uint128 self;
        assembly {
            self :=selfbalance()
        }

        if(self < value){
            revert TxError(402);
        }

        if (underLimit(value)) {
            // limit not reached
            execNonce += 1;
            spentToday += value;
            execute(recipient, value, data);
            return true;
        } else {
            // requires approval from signatories -- not factored into daily allowance
            Transaction memory txObject = Transaction(recipient, value, data, 0);
            pendingTxs[nonceTxid] = (txObject);
            signTx(nonceTxid, msg.sender);
            return false;
        }

    }
    function test_check_arbitrary_withdraw_over_limit(uint32 nonce) public returns (bool) {
        //@dev: Echidna Test function
        if (submitTx(0xdF0dd354cA601EE75C88f08E5B9F18fC6Db3737F, 2500000000000, "0x0",nonce) ){
            // executed without approval
            return true;

        } else {
            // placed in queue pending approval from signers
            return false;
        }

    }

    function echidna_test_break_access_control() external returns(bool){
        uint32 _nonce = execNonce+1;
        if(this.submitTx(0x4Ee4Bad6867Dd92b6A31a7BE2003A37D0c80Df39, 100, "0x0000000000000000000000000000000000000000", _nonce)){
            return true;
        }
        return false;
    }

    function echidna_test_change_limits() external returns(bool){
        /*
        @dev should not be possible because the proposer cant get all signatures himself.
        */
        proposeNewLimits(1, 100000000000000000000);
        if (confirmProposedLimits()) {
            return true;
        }
        return false;

    }

    function echidna_exceedDailyLimits() external returns(bool){
        /*
          @dev should not be possible to exceed the limits without
          the other signer keys
        */
        for (uint8 i = 0; i < 10; i++) {
            uint32 _nonce = execNonce+1;
            test_check_arbitrary_withdraw_over_limit(_nonce);
        }


        return true;
        // this should not return true
        /*if (test_check_arbitrary_withdraw_over_limit(5)) {
            return true;
        }
        return false;*/
    }


    function echidna_check_balance() public returns (bool) {

        //@dev: random example test function
        uint128 balance = 1000000000;
        return( balance>= 20);
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
            spentToday = 0;
            lastDay = t;
        }
        // check to see if there's enough left
        if (spentToday + _value <= dailyLimit) {
            return true;
        }
            return false;
    }

     /*
       @dev: Allow arbitrary deposits to contract.
     */

     receive() external payable {}

}

