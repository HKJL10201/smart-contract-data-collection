//! Copyright Parity Technologies, 2017.
//! Released under the Apache Licence 2.

pragma solidity ^0.4.24;

import "../Libraries/SafeMath.sol";


contract Token {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approveAndCall(address _spender, uint _amount, bytes _data) public returns (bool success);
}


contract Certifier {
    event Confirmed(address indexed who);
    event Revoked(address indexed who);
    function certified(address) public view returns (bool);
    function get(address, string) public view returns (bytes32);
    function getAddress(address, string) public view returns (address);
    function getUint(address, string) public view returns (uint);
}


 /**
 * @title SecondPriceAuction
 * @author Parity Technologies, 2017.  Modifications made by Connor Howe - ConnorBlockchain.
 * @dev Simple modified second price auction contract. Price starts high and monotonically decreases
 until all tokens are sold at the current price with currently received funds. The price curve
 has been chosen to resemble a logarithmic curve and produce a reasonable auction timeline.
 Requires softcap to be met, before finalisation, and if finalisation is not met a refund will be available.
 */
contract SecondPriceAuction {
    using SafeMath for uint256;

    /* ---- Events ---- */
    /// @dev Someone bought in at a particular max-price.
    event Buyin(address indexed who, uint accounted, uint received, uint price);

    /// @dev Admin injected a purchase.
    event Injected(address indexed who, uint accounted, uint received);

    /// @dev Admin uninjected a purchase.
    event Uninjected(address indexed who);

    /// @dev The sale just ended with the current price.
    event Ended(uint price);

    /// @dev Finalised the purchase for `who`, who has been given `tokens` tokens.
    event Finalised(address indexed who, uint tokens);

    /// @dev Sale did not reach softcap.
    event SoftCapNotReached(uint indexed totalReceived, uint usdWEISoftCap, address indexed _who);

    /// @dev Auction is over. All accounts finalised.
    event Retired();

   /**
    * @dev Initializes instance of Token & Certifier contract, and assigns all values.
    * @param _certifierContract Address of Certifier contract.
    * @param _tokenContract Address of ERC20 contract.
    * @param _tokenVesting Address of TokenVesting contract.
    * @param _treasury Address of treasury.
    * @param _admin Address of admin.
    * @param _beginTime Start time of dutch auction.
    * @param _tokenCap Token cap in whole tokens (decimals).
    */
    constructor(
        address _certifierContract,
        address _tokenContract,
        address _tokenVesting,
        address _treasury,
        address _admin,
        uint _beginTime,
        uint _tokenCap
    ) public {
        certifier = Certifier(_certifierContract);
        tokenContract = Token(_tokenContract);
        tokenVesting = _tokenVesting;
        treasury = _treasury;
        admin = _admin;
        beginTime = _beginTime;
        tokenCap = _tokenCap;
        endTime = beginTime.add(15 days);
    }

    /* ---- Public Functions ---- */
   /**
    * @dev User buys in to auction, and throws if not active and when refund needed.
    */
    function buyin(uint8 v, bytes32 r, bytes32 s)
        public
        payable
        whenNotHalted
        notPreSaleMember(msg.sender)
        whenActive
        onlyEligible(msg.sender, v, r, s)
    {
        if (currentBonus > 0 && currentBonusRound <= 4) {
        // Bonus is currently active...
            if (now >= beginTime.add(BONUS_MAX_DURATION)) {
                currentBonus = 0;
                currentBonusRound++;
            } else if (now >= beginTime.add(BONUS_MAX_DURATION_ROUND.mul(currentBonusRound))) {
                currentBonus -= 5;
                currentBonusRound++;
            }
        }

        uint accounted;
        bool refund;
        uint price;
        (accounted, refund, price) = theDeal(msg.value);

        /// No refunds allowed.
        require(!refund);

        // record the acceptance.
        buyins[msg.sender].accounted = accounted.add(buyins[msg.sender].accounted);
        buyins[msg.sender].received = msg.value.add(buyins[msg.sender].received);
        totalAccounted = totalAccounted.add(accounted);
        totalReceived = totalReceived.add(msg.value);
        emit Buyin(msg.sender, accounted, msg.value, price);
    }

   /**
    * @dev Similar to buyin except no payment reqired and bonus automatically given, only callable by admin.
    * @param _who Address of pre-sale member.
    * @param _received Amount of ether that the pre-sale member contributed.
    * @param _appliedBonus Bonus agreed in pre-sale agreement.
    */
    function inject(address _who, uint256 _received, uint256 _appliedBonus)
        public
        onlyAdmin
        onlyBasic(_who)
        beforeBeginning
    {
        uint256 bonus = _received.mul(_appliedBonus).div(100);
        uint256 accounted = _received.add(bonus);

        buyins[_who].accounted = accounted.add(buyins[_who].accounted);
        buyins[_who].received = _received.add(buyins[_who].received);
        buyins[_who].presale = true;
        totalAccounted = totalAccounted.add(accounted);
        totalReceived = totalReceived.add(_received);
        emit Injected(_who, accounted, _received);
    }

   /**
    * @dev Reverses previous injection function, only callable by admin.
    * @param _who Address of pre-sale member to reverse injection.
    */
    function uninject(address _who)
        public
        onlyAdmin
        beforeBeginning
    {
        totalAccounted = totalAccounted.sub(buyins[_who].accounted);
        totalReceived = totalReceived.sub(buyins[_who].received);
        delete buyins[_who];
        emit Uninjected(_who);
    }

   /**
    * @dev Calculates final token price, and transfers tokens to _who when
    softcap and time met.  If presale member, approveAndCall will auto call TokenVesting contract.
    * @param _who Address of pre-sale member to transfer tokens
    */
    function finalise(address _who)
        public
        whenNotHalted
        whenEnded
        whenSoftMet
        onlyBuyins(_who)
    {
        if (endPrice == 0) {
            endPrice = (totalAccounted.mul(DIVISOR).div(tokenCap));
            emit Ended(endPrice);
        }

        uint total = buyins[_who].accounted;
        uint tokens = (total.div(endPrice)).mul(DIVISOR);
        totalFinalised = totalFinalised.add(total);
        bool presale = buyins[_who].presale;

        delete buyins[_who];

        if (presale) {
            require(tokenContract.approveAndCall(tokenVesting, tokens, toBytes(_who)));
        } else {
            require(tokenContract.transfer(_who, tokens));
        }

        emit Finalised(_who, tokens);

        if (totalFinalised == totalAccounted) {
            isFinalized = true;
            emit Retired();
        }
    }

   /**
    * @dev Returns ether to participant if softcap is not met.
    * @param _who Address of pre-sale member to refund tokens to.
    */
    function claimRefund(address _who)
        public
        whenNotHalted
        whenEnded
        whenSoftNotMet
        onlyBuyins(_who)
    {
        //TODO; add check if already emitted
        emit SoftCapNotReached(totalReceived, usdWEISoftCap, _who);

        uint total = buyins[_who].received;
        totalFinalised = totalFinalised.add(total);
        delete buyins[_who];
        _who.transfer(total);

        if (totalFinalised == totalReceived) {
            emit Retired();
        }
    }

    /* ---- Admin Functionality ---- */
   /**
    * @dev Admin can change stored USDWEI value of ether if bull run occurs.
    * @param _usdWEI Amount of WEI to 1 USD.
    */
    function setUSDWei(uint _usdWEI)
        public
        onlyAdmin
        whenActive
    {
        usdWEI = _usdWEI;
    }

   /**
    * @dev Admin can change softcap USDWEI value of 10m if bull run occurs.
    * @param _usdWEISoftCap Amount of WEI to 10m USD.
    */
    function setUSDSoftCap(uint _usdWEISoftCap)
        public
        onlyAdmin
        whenActive
    {
        usdWEISoftCap = _usdWEISoftCap;
    }

   /**
    * @dev Admin emergency function to pause buy-in and finalisation.
    * @param _halted Bool to transition contract to halted state or not.
    */
    function setHalted(bool _halted)
        public
        onlyAdmin
    {
        halted = _halted;
    }

   /**
    * @dev Admin emergency function to drain the contract of any funds.
    */
    function drain()
        public
        onlyAdmin
    {
        treasury.transfer(address(this).balance);
    }

    // Inspection:
    /**
    * The formula for the price over time.
    *
    * This is a hand-crafted formula (no named to the views) in order to
    * provide the following requirements:
    *
    * - Simple reciprocal curve (of the form y = a + b / (x + c));
    * - Would be completely unreasonable to end in the first 48 hours;
    * - Would reach $65m effective cap in 4 weeks.
    *
    * The curve begins with an effective cap (EC) of over $30b, more ether
    * than is in existance. After 48 hours, the EC reduces to approx. $1b.
    * At just over 10 days, the EC has reduced to $200m, and half way through
    * the 19th day it has reduced to $100m.
    *
    * Here's the curve: https://www.desmos.com/calculator/k6iprxzcrg?embed
    */
    /// y = [33200 / (x + 80) - 65] / 350
    /// Where x is the number of hours passed since the beginning of the auction.
    /*
    Where x is the number of hours passed since the beginning of the auction.
    Per this formula, the token price after the first day is approximately $0.72 priced in ETH,
    after the first week is approximately $0.20 priced in ETH, etc.
    */
    /// The current price for a single indivisible part of a token. If a buyin happens now, this is
    /// the highest price per indivisible token part that the buyer will pay. This doesn't
    /// include the discount which may be available.
   /**
    * @return The current price of 1 token in usdWEI.
    */
    function currentPrice()
        public view
        whenActive
        returns (uint)
    {
        if (hoursPassed() == 0) {
            return usdWEI;
        }
        return (usdWEI.mul(33200).div((hoursPassed().add(80))).sub(usdWEI.mul(65))).div(350);
    }

   /**
    * @return Amount of hours that the auction has passed.
    */
    function hoursPassed()
        public
        view
        returns (uint)
    {
        return (now.sub(beginTime)).div(1 hours);
    }

   /**
    * @return Total indivisible token parts available for purchase right now.
    */
    function tokensAvailable()
        public
        view
        whenActive
        returns (uint tokens)
    {
        uint _currentCap = totalAccounted.div(currentPrice());
        if (_currentCap >= tokenCap) {
            return 0;
        }
        return tokenCap.sub(_currentCap);
    }

   /**
    * @return The largest purchase that can be made at present, not including any discount.
    */
    function maxPurchase()
        public
        view
        whenActive
        returns (uint spend)
    {
        return tokenCap.mul(currentPrice()).sub(totalAccounted);
    }

   /**
    * @dev Amount of tokens that would be given to the sender if they were to spent _value now.
    * @param _value Ether amount of potential purchase.
    * @return Amount of tokens.
    */
    function theDeal(uint _value)
        public
        view
        whenActive
        returns (uint accounted, bool refund, uint price)
    {
        uint _bonus = bonus(_value);

        price = currentPrice();
        accounted = _value.add(_bonus);

        uint available = tokensAvailable();
        uint tokens = accounted.div(price);
        refund = (tokens > available);
    }

   /**
    * @dev If bonus is still occuring, and if so what would the token amount be once bonus applied.
    * @param _value Ether amount of potential purchase.
    * @return Amount of tokens + bonus.
    */
    function bonus(uint _value)
        public
        view
        whenActive
        returns (uint extra)
    {
        return _value.mul(uint(currentBonus)).div(100);
    }

   /**
    * @return The current time.
    */
    function currentTime() public view returns (uint) { return now;}

   /**
    * @return True if the sale is ongoing.
    */
    function isActive() public view returns (bool) { return now >= beginTime && now < endTime; }

   /**
    * @return True if all buyins have finalised.
    */
    function allFinalised() public view returns (bool)
    {
        return now >= endTime && totalAccounted == totalFinalised;
    }

   /**
    * @return True if ether recieved greater than softcap.
    */
    function softCapMet() public view returns (bool) { return totalReceived >= usdWEISoftCap; }

   /**
    * @dev Recover address from msg signature.
    * @param msgHash Hash of terms and conditions.
    */
    function recoverAddr(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));
        return ecrecover(prefixedHash, v, r, s);
    }

   /**
    * @dev Check if signature has been signed by _addr.
    * @param _addr Address to check if signature has been signed by.
    * @param msgHash Hash of terms and conditions.
    */
    function isSigned(
        address _addr,
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        pure
        returns (bool)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));
        return ecrecover(prefixedHash, v, r, s) == _addr;
    }

   /**
    * @dev Check if who address can purchase via buyin function.
    * @param who Address to check if signature has been signed b and KYC has passed.
    */
    function eligibleCall(
        address who,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        view
        returns(bool)
    {
        require(
            recoverAddr(STATEMENT_HASH, v, r, s) == who &&
            certifier.certified(who) &&
            isBasicAccount(who)
        );
        return true;
    }

    /* ---- Private Functions ---- */
   /**
    * @return True if address is not a contract address.
    * @param _who Address to check.
    */
    function isBasicAccount(address _who) private view returns (bool) {
        uint senderCodeSize;
        assembly {
            senderCodeSize := extcodesize(_who)
        }
        return senderCodeSize == 0;
    }

   /**
    * @dev Converts address to bytes format.
    * @param a Address to convert.
    */
    function toBytes(address a)
        private
        pure
        returns (bytes b)
    {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    /* ---- Function Modifiers ---- */
    /// Ensure the sale is ongoing.
    modifier whenActive { require(isActive()); _; }

    /// Ensure the sale has not begun.
    modifier beforeBeginning { require(now < beginTime); _; }

    /// Ensure the sale is ended.
    modifier whenEnded { require(now >= endTime); _; }

    /// Ensure we're not halted.
    modifier whenNotHalted { require(!halted); _; }

    /// Ensure soft cap has been met.
    modifier whenSoftMet { require(softCapMet()); _; }

    /// Ensure soft cap has not been met.
    modifier whenSoftNotMet { require(!softCapMet()); _; }

    /// Ensure `_who` is a participant.
    modifier onlyBuyins(address _who) { require(buyins[_who].accounted != 0); _; }

    /// Ensure same address for pre-sale is not used for public, to ensure clear
    /// devide of vested tokens and non-vested tokens.
    modifier notPreSaleMember(address _who) { require(!buyins[_who].presale); _;}

    /// Ensure sender is admin.
    modifier onlyAdmin { require(msg.sender == admin); _; }

    /// Ensure that the signature is valid, `who` is a certified, basic account,
    /// the gas price is sufficiently low and the value is sufficiently high.
    modifier onlyEligible(address who, uint8 v, bytes32 r, bytes32 s) {
        require(
            recoverAddr(STATEMENT_HASH, v, r, s) == who &&
            certifier.certified(who) &&
            isBasicAccount(who) &&
            msg.value >= DUST_LIMIT
        );
        _;
    }

    /// Ensure sender is not a contract.
    modifier onlyBasic(address who) { require(isBasicAccount(who)); _; }

    // State:
    struct Account {
        uint256 accounted;    // including bonus & hit
        uint256 received;    // just the amount received, without bonus & hit
        bool presale; // if the investor was involved in presale & funds will be locked for vesting period.
    }

    /// Those who have bought in to the auction.
    mapping (address => Account) public buyins;

    /// Total amount of ether received, excluding phantom "bonus" ether.
    uint public totalReceived = 0;

    /// Total amount of ether accounted for, including phantom "bonus" ether.
    uint public totalAccounted = 0;

    /// Total amount of ether which has been finalised.
    uint public totalFinalised = 0;

    /// Current iteration of bonus round.
    uint public currentBonusRound = 1;

    /// The current end time. Gets updated when new funds are received.
    uint public endTime;

    /// The price per token; only valid once the sale has ended and at least one
    /// participant has finalised.
    uint public endPrice;

    /// Must be false for any public function to be called.
    bool public halted;

    /// The current percentage of bonus that purchasers get.
    uint8 public currentBonus = 20;

    // views after constructor:

    /// The tokens contract.
    Token public tokenContract;

    /// The certifier.
    Certifier public certifier;

    /// The tokens vesting contract.
    address public tokenVesting;

    /// The treasury address; where all the Ether goes.
    address public treasury;

    /// The admin address; auction can be paused or halted at any time by this.
    address public admin;

    /// The time at which the sale begins.
    uint public beginTime;

    /// Maximum amount of tokens to mint. Once totalAccounted / currentPrice is
    /// greater than this, the sale ends.
    uint public tokenCap;

    // If finalized all transfers
    bool public isFinalized;

    /// Number of Wei in one USD.
    uint public usdWEI = 4520 szabo;

    /// Soft cap 10m USD in wei.
    uint public usdWEISoftCap = 45200 ether;


    // Static views:

    /* solhint-disable */
    /// Anything less than this is considered dust and cannot be used to buy in.
    uint constant public DUST_LIMIT = 5 finney;

    /// The hash of the statement which must be signed in order to buyin.
    /// The meaning of this hash is:
    ///
    // STATEMENT_HASH = web3.sha3("\x19Ethereum Signed Message:\n" + TLCS.length + TLCS);
    // TLCS = 'This is an example terms and conditions.';
    bytes32 constant public STATEMENT_HASH = 0x296ee19d9322038f648ced3996d1909faa1eaf9fd6d1340f49180822eb0f8776;

    /// Minimum duration after sale begins that bonus is active.
    uint constant public BONUS_MIN_DURATION = 1 hours;

    /// Minimum duration after sale begins that bonus is active.
    uint constant public BONUS_MAX_DURATION = 4 days;

    // Maximum duration of each bonus round is active
    uint constant public BONUS_MAX_DURATION_ROUND = 24 hours;

    /// Number of consecutive blocks where there must be no new interest before bonus ends.
    uint constant public BONUS_LATCH = 2;

    /// Divisor of the token.
    uint constant public DIVISOR = 1000000000000000000;
    /* solhint-enable */
}
