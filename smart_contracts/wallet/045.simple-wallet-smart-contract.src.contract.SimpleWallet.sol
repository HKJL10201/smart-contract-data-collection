pragma ton-solidity >= 0.58.2;

/**
 * Errors
 *     100 - Method for the owner only
 *     101 - Owner public key cannot be null
 */
contract SimpleWallet {
    /*************
     * MODIFIERS *
     *************/
    modifier accept {
        tvm.accept();
        _;
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), 100, "Method for the owner only");
        _;
    }

    modifier ownerIsNotNull(uint256 owner) {
        require(owner != 0, 101, "Owner public key cannot be null");
        _;
    }



    /***************
     * CONSTRUCTOR *
     ***************/
    constructor() public onlyOwner ownerIsNotNull(tvm.pubkey()) accept {}



    /***********************
     * PUBLIC * ONLY OWNER *
     ***********************/
    /**
     * @param owner {uint256} New public key of owner.
     * Example:
     *     '0x7d1abef2b7e4f1d4de1447d226092f0db53c9ef71509d43c963dcdf94a4a51de2'
     */
    function changeOwner(uint256 owner) public onlyOwner ownerIsNotNull(owner) accept {
        tvm.setPubkey(owner);
    }

    /**
     * @param dest {uint256} Destination address.
     * Example:
     *     '0:e16969e5e83ebf73aed8954e05f897375bd9623261c36be8b685140fdc2d46eb'
     * @param value {uint128} Value in nano grams.
     * Example:
     *     '1000000000'
     * @param bounce {bool} It's set and deploying falls (only at computing phase, not at action phase!)
     *     then funds will be returned. Otherwise (flag isn't set or deploying terminated successfully) the
     *     address accepts the funds. Defaults to true
     * @param flags {uint8} Bit-mask flags.
     * https://ton.org/tvm.pdf
     *     0   - ordinary message
     *     1   - the sender wants to pay transfer fees separately
     *     2   - any errors arising while processing this message during the action phase should be ignored
     *     32  - current account must be destroyed if its resulting balance is zero
     *     64  - messages that carry all the remaining value of the inbound message in addition to the value initially
     *           indicated in the new message (if bit 0 is not set, the gas fees are deducted from this amount)
     *     128 - to carry all the remaining balance of the current smart contract (instead of the value originally
     *           indicated in the message)
     * @param payload {TvmCell} Attached to the internal message. Defaults to an empty TvmCell.
     */
    function sendTransaction(address dest, uint128 value, bool bounce, uint16 flags, TvmCell payload)
        public
        pure
        onlyOwner
        accept
    {
        dest.transfer(value, bounce, flags, payload);
    }

    /**
     * @param code {TvmCell} New version of contract code.
     */
    function upgrade(TvmCell code) public pure onlyOwner accept {
        tvm.setcode(code);
        tvm.setCurrentCode(code);
        onCodeUpgrade();
    }



    /***********
     * GETTERS *
     ***********/
    function getOwner() public view returns(uint256 owner) {
        return tvm.pubkey();
    }



    /**************************
     * PURE * ON CODE UPGRADE *
     **************************/
    function onCodeUpgrade() private pure {}
}