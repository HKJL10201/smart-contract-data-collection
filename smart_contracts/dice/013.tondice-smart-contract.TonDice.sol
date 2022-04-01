pragma solidity >= 0.6.2;

import 'modifiers/TransferValueModifier.sol';

/**
 * ████████╗ ██████╗ ███╗   ██╗    ██████╗ ██╗ ██████╗███████╗
 * ╚══██╔══╝██╔═══██╗████╗  ██║    ██╔══██╗██║██╔════╝██╔════╝
 *    ██║   ██║   ██║██╔██╗ ██║    ██║  ██║██║██║     █████╗
 *    ██║   ██║   ██║██║╚██╗██║    ██║  ██║██║██║     ██╔══╝
 *    ██║   ╚██████╔╝██║ ╚████║    ██████╔╝██║╚██████╗███████╗
 *    ╚═╝    ╚═════╝ ╚═╝  ╚═══╝    ╚═════╝ ╚═╝ ╚═════╝╚══════╝
 * First dice on Free TON
 *
 * Error codes
 *     • 100 — Method only for the owner
 *     • 101 — Bet value is less than the minimum value
 *     • 102 — Bet value is more than the maximum value
 *     • 103 — Number is less than the minimum value
 *     • 104 — Number is more than the maximum value
 *
 *     • 200 — Transfer value is zero
 *     • 201 — Transfer value is more than balance
 */
contract TonDice is TransferValueModifier {
    /**********
     * EVENTS *
     **********/
    event BetEvent(
        uint64  timestamp,
        address addr,
        uint128 betValue,
        uint8   betNumber,
        uint128 resultValue,
        uint8   resultNumber,
        uint256 referralId
    );



    /*************
     * CONSTANTS *
     *************/
    uint32  private constant RETURN_TO_PLAYER_DECIMALS = 1e9;
    uint16  private constant MAX_REFERRAL_ID_LENGTH    = 256;
    uint8   private constant NUMBERS                   = 100;



    /*************
     * VARIABLES *
     *************/
    uint32  private _version;
    uint128 private _minBetValue;
    uint128 private _maxBetValue;
    uint8   private _minBetNumber;
    uint8   private _maxBetNumber;
    uint32  private _returnToPlayer;



    /*************
     * MODIFIERS *
     *************/
    modifier accept {
        tvm.accept();
        _;
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), 100, "Method only for owner");
        _;
    }

    modifier validBetValue {
        require(msg.value >= _minBetValue, 101, "Bet value is less than the minimum value");
        require(msg.value <= _maxBetValue, 102, "Bet value is more than the maximum value");
        _;
    }

    modifier validBetNumber(uint8 number) {
        require(number >= _minBetNumber, 103, "Number is less than the minimum value");
        require(number <= _maxBetNumber, 104, "Number is more than the maximum value");
        _;
    }



    /***************
     * CONSTRUCTOR *
     ***************/
    constructor() public accept {
        _version        = 1;
        _minBetValue    = 1e9;     // 1💎
        _maxBetValue    = 100e9;   // 100💎
        _minBetNumber   = 5;       // Win chance is 95%
        _maxBetNumber   = 98;      // Win chance is 2%
        _returnToPlayer = 0.985e9; // 98.5% crystals returns to player
    }



    /***********
     * GETTERS *
     ***********/
    function getVersion()        public view returns (uint32  version)        { return _version; }
    function getMinBetValue()    public view returns (uint128 minBetValue)    { return _minBetValue; }
    function getMaxBetValue()    public view returns (uint128 maxBetValue)    { return _maxBetValue; }
    function getMinBetNumber()   public view returns (uint8   minBetNumber)   { return _minBetNumber; }
    function getMaxBetNumber()   public view returns (uint8   maxBetNumber)   { return _maxBetNumber; }
    function getReturnToPlayer() public view returns (uint32  returnToPlayer) { return _returnToPlayer; }



    /***********
     * SETTERS *
     ***********/
    function setMinBetValue (uint128 value) public onlyOwner accept returns (uint128 previous, uint128 current) {
        previous = _minBetValue;
        current = _minBetValue = value;
    }

    function setMaxBetValue (uint128 value) public onlyOwner accept returns (uint128 previous, uint128 current) {
        previous = _maxBetValue;
        current = _maxBetValue = value;
    }

    function setMinBetNumber (uint8 value) public onlyOwner accept returns (uint8 previous, uint8 current) {
        previous = _minBetNumber;
        current = _minBetNumber = value;
    }

    function setMaxBetNumber (uint8 value) public onlyOwner accept returns (uint8 previous, uint8 current) {
        previous = _maxBetNumber;
        current = _maxBetNumber = value;
    }

    function setReturnToPlayer(uint32 value) public onlyOwner accept returns (uint32 previous, uint32 current) {
        previous = _returnToPlayer;
        current = _returnToPlayer = value;
    }



    /***********************
     * PUBLIC * ONLY OWNER *
     ***********************/
    function sendTransaction(
        address destination,
        uint128 value,
        bool    bounce,
        uint8   flag
    ) public view onlyOwner accept validTransferValue(value) {
        destination.transfer(value, bounce, flag);
    }

    function setCode(TvmCell newCode) public onlyOwner accept {
        tvm.setcode(newCode);
        tvm.setCurrentCode(newCode);
        _onCodeUpgrade();
    }

    function _onCodeUpgrade() private {}



    /************
     * EXTERNAL *
     ************/
    function bet(uint8 number, uint256 referralId) external view validBetValue validBetNumber(number) returns (
        uint64  timestamp,
        address addr,
        uint128 betValue,
        uint8   betNumber,
        uint128 resultValue,
        uint8   resultNumber
    ){
        timestamp = tx.timestamp;
        addr = msg.sender;
        betValue = msg.value;
        betNumber = number;
        resultNumber = _getResultNumber();
        resultValue = _getResultValue(betValue, betNumber, resultNumber, _returnToPlayer);
        emit BetEvent(timestamp, addr, betValue, betNumber, resultValue, resultNumber, referralId);
        if (resultValue > 0)
            addr.transfer(resultValue);
    }



    /********
     * PURE *
     ********/
    /**
     * Returns random number from range 0..99 inclusive.
     */
    function _getResultNumber() private pure returns (uint8) {
        rnd.shuffle();
        return rnd.next(NUMBERS);
    }

    /**
     * Returns payout value for player.
     * Example:
     *     PARAMETERS:
     *         NUMBERS = 100
     *         RETURN_TO_PLAYER_DECIMALS = 1'000'000'000
     *
     *         betValue = 10'000'000'000
     *         betNumber = 5
     *         resultNumber = 99
     *         returnToPlayer = 985'000'000
     *
     *    CALCULATION:
     *         luckyNumbersCount = NUMBERS - betNumber
     *         luckyNumbersCount = 100 - 5
     *         luckyNumbersCount = 95
     *
     *         winValue = betValue * NUMBERS / luckyNumbersCount
     *         winValue = 10'000'000'000 * 100 / 95
     *         winValue = 10'526'315'789
     *
     *         result = winValue * returnToPlayer / RETURN_TO_PLAYER_DECIMALS
     *         result = 10'526'315'789 * 985'000'000 / 1'000'000'000
     *         result = 10'368'421'052
     *
     *     RESULT:
     *         10'368'421'052
     */
    function _getResultValue(
        uint128 betValue,
        uint8   betNumber,
        uint8   resultNumber,
        uint64  returnToPlayer
    ) private pure returns (uint128) {
        if (resultNumber < betNumber) return 0;
        uint8 luckyNumbersCount = NUMBERS - betNumber;
        uint128 winValue = math.muldiv(betValue, NUMBERS, luckyNumbersCount);
        return math.muldiv(winValue, returnToPlayer, RETURN_TO_PLAYER_DECIMALS);
    }
}