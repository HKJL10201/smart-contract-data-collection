pragma solidity ^0.4.24;

import "../Libraries/SafeMath.sol";
import "../Libraries/Ownable.sol";


contract Token {
    function transferFrom(address _from, address _to, uint _amount) public returns (bool success);
    function approveAndCall(address _spender, uint _amount, bytes _data) public returns (bool success);
    function allowance(address _tokenHolder, address _spender) public view returns (uint remaining);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
}


/**
 * @title TokenVesting
 * @author Connor Howe - ConnorBlockchain
 * @dev This contract manages pre-sale tokens with particular vesting periods.
 */
contract TokenVesting is Ownable {
    using SafeMath for uint256;


    /* ---- Events ---- */
    event TokensReleased(address indexed who, uint256 amount);
    event Registration(address indexed who, uint256 indexed cliff, uint256 indexed duration);
    event TokensRecieved(address indexed who, uint256 indexed amount, uint256 indexed timestamp);
    event TokenVestingRevoked(address indexed who, uint256 indexed amount);
    event AuctionAddressAssigned(address indexed auctionAddress);
    event LockUpdated(bool indexed lockActive);
    event EmergencyDrain(address indexed emergencyAddress, uint indexed amount);
    event Released(uint256 amount);
    event Revoked();


    /* ---- Storage ---- */
    address public tokenAddress;
    address public auctionAddress;
    Token public TrustedTokenContract;

    bool public locked;
    bool public isFinalized;
    uint256 public totalAccounted;
    uint256 public totalReleased;

    struct UserData {
        uint128 cliff;
        uint256 start;
        uint64 duration;
        uint256 unreleased;
        uint256 released;
        bool revocable;
    }

    mapping (address => UserData) public userData;
    mapping (address => bool) public revoked;
    mapping (address => bool) public registered;

    /**
     * @dev Initializes instance of Token Contract and assigns address.
     * @param _tokenWOM Address of ERC20 token contract for WOM.
     */
    constructor(address _tokenWOM) public notEmptyAddress(_tokenWOM) {
        tokenAddress = _tokenWOM;
        TrustedTokenContract = Token(_tokenWOM);
    }

    /* ---- Public Functions ---- */
   /**
    * @dev Owner registers pre-sale amount and agreed vesting terms.
    * @param _revocable Whether owner can revoke unreleased tokens if a breach in vesting contract.
    * @param _who The persons address.
    * @param _cliff Epoch seconds for cliff time.
    * @param _duration Epoch seconds for duration of vest.
    */
    function registerPresaleVest(
        bool _revocable,
        address _who,
        uint128 _cliff,
        uint64 _duration
    )
        public
        notLocked
        onlyOwner
        notEmptyUint(_cliff)
        notEmptyUint(_duration)
        notEmptyAddress(_who)
        notRegistered(_who)
    {
        registered[_who] = true;
        userData[_who].revocable = _revocable;
        userData[_who].cliff = _cliff;
        userData[_who].duration = _duration;
        emit Registration(_who, _cliff, _duration);
    }

   /**
    * @dev Called once SecondPriceAuction finalise() called, and then the ERC20 calls this function.
    * @param from SecondPriceAuction address.
    * @param tokens Amount of tokens that has been approved.
    * @param token Address of ERC20 token.
    * @param data Bytes conversion of pre-sale members address.
    */
    function receiveApproval(address from, uint tokens, address token, bytes data)
        public
    {
        require(data.length == 20);
        require(msg.sender == tokenAddress);
        require(from == auctionAddress);
        require(token == tokenAddress);
        address _who = bytesToAddress(data);
        require(registered[_who]);
        totalAccounted = totalAccounted.add(tokens);
        userData[_who].unreleased = tokens;
        userData[_who].start = now;
        emit TokensRecieved(_who, tokens, now);
    }

   /**
    * @dev Pre-sale members release their locked up funds.
    */
    function release()
        public
        notLocked
    {
        require(registered[msg.sender]);

        uint256 _releaseAmount = _releasableAmount(msg.sender);

        require(_releaseAmount > 0);

        userData[msg.sender].released = userData[msg.sender].released.add(_releaseAmount);
        userData[msg.sender].unreleased = userData[msg.sender].unreleased.sub(_releaseAmount);

        if (_allReleased(msg.sender)) {
            delete registered[msg.sender];
            delete userData[msg.sender];
        }

        totalReleased = totalReleased.add(_releaseAmount);

        TrustedTokenContract.transferFrom(auctionAddress, msg.sender, _releaseAmount);

        if (totalAccounted == totalReleased) {
            isFinalized = true;
        }
        emit TokensReleased(msg.sender, _releaseAmount);
    }

   /**
    * @dev Owner revokes users remaining unreleased funds, and transfers to an emergency address.
    * @param _who Pre-sale members address to revoke future releases.
    * @param _emergencyAddress Address remainder of pre-sale users unreleased tokens will be transfered to.
    */
    function revoke(address _who, address _emergencyAddress)
        public
        onlyOwner
        notLocked
    {
        require(registered[_who]);
        require(userData[_who].revocable);
        require(!revoked[_who]);

        uint256 _unreleased = userData[_who].unreleased;
        userData[_who].unreleased = 0;

        totalAccounted = totalAccounted.sub(_unreleased);

        revoked[_who] = true;

        TrustedTokenContract.transferFrom(auctionAddress, _emergencyAddress, _unreleased);

        emit TokenVestingRevoked(_who, _unreleased);
    }

    /* ---- View Getters ---- */
   /**
    * @return Epoch seconds of users Cliff.
    */
    function getCliff(address _who) public view returns(uint256) {
        return userData[_who].cliff;
    }

   /**
    * @return The start time of token vesting.
    */
    function getStart(address _who) public view returns(uint256) {
        return userData[_who].start;
    }

   /**
    * @return The duration of the token vesting.
    */
    function getDuration(address _who) public view returns(uint256) {
        return userData[_who].duration;
    }

   /**
    * @return True if the vesting is revocable.
    */
    function getRevocable(address _who) public view returns(bool) {
        return userData[_who].revocable;
    }

   /**
    * @return The amount of tokens released.
    */
    function getReleased(address _who) public view returns(uint256) {
        return userData[_who].released;
    }

   /**
    * @return The amount of tokens unreleased.
    */
    function getUnreleased(address _who) public view returns(uint256) {
        return userData[_who].unreleased;
    }

   /**
    * @return If all pre-sale tokens have been released/claimed..
    */
    function getFinalized() public view returns(bool) {
        return isFinalized;
    }

    /* ---- Admin Functionality ---- */
   /**
    * @dev Owner assigns SecondPriceAuction address for lookups and transfers.
    * @param _auctionAddress SecondPriceAuction address.
    */
    function setAuctionAddress(address _auctionAddress)
        public
        onlyOwner
    {
        require(auctionAddress == address(0));
        auctionAddress = _auctionAddress;
        emit AuctionAddressAssigned(_auctionAddress);
    }

   /**
    * @dev Owner can lock the contract incase a vulnerability is found.
    * @param _lock Bool assign lock.
    */
    function setLock(bool _lock)
        public
        onlyOwner
    {
        locked = _lock;
        emit LockUpdated(_lock);
    }

   /**
    * @dev Owner can drain all remaining unreleased pre-sale tokens incase a vulnerability is found.
    * @param _emergencyAddress Address where total unrealeased tokens will be transferred too.
    */
    function emergencyDrain(address _emergencyAddress)
        public
        onlyOwner
    {
        require(locked);
        uint256 balanceOf = TrustedTokenContract.allowance(auctionAddress, this);
        TrustedTokenContract.transferFrom(auctionAddress, _emergencyAddress, balanceOf);
        emit EmergencyDrain(_emergencyAddress, balanceOf);
    }

    /**
     * @dev Owner can drain set _amount of tokens incase a vulnerability is found, and incase emergencyDrain() fails with call to external contract.
     * @param _emergencyAddress Address where total unrealeased tokens will be transferred too.
     * @param _amount Amount of tokens to be drained from allowance.
     */
     function emergencyDrainBackup(address _emergencyAddress, uint256 _amount)
         public
         onlyOwner
     {
         require(locked);
         TrustedTokenContract.transferFrom(auctionAddress, _emergencyAddress, _amount);
         emit EmergencyDrain(_emergencyAddress, _amount);
     }

    /* ---- Private Functions ---- */
   /**
    * @dev Calculates the amount that has already vested but hasn't been released yet.
    */
    function _releasableAmount(address _who) private view returns (uint256) {
        return _vestedAmount(_who).sub(userData[_who].released);
    }

   /**
    * @dev Determines if user has released all of their funds.
    */
    function _allReleased(address _who) private view returns(bool) {
        return (userData[_who].unreleased == 0);
    }

   /**
    * @dev Calculates the amount that has already vested.
    */
    function _vestedAmount(address _who) private view returns (uint256) {
        uint256 currentBalance = userData[_who].unreleased;
        uint256 totalBalance = currentBalance.add(userData[_who].released);

        if (now < getCliff(_who)) {
            return 0;
        } else if (now >= getStart(_who).add(getDuration(_who)) || revoked[_who]) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(getStart(_who))).div(getDuration(_who));
        }
    }

   /**
    * @return converts bytes to address.
    */
    function bytesToAddress(bytes bys) private view returns (address addr) {
        assembly {
        addr := mload(add(bys, 20))
        }
    }

    /* ---- Function Modifiers ---- */
    modifier notRegistered(address _who) { require(!registered[_who]); _; }
    modifier notEmptyAddress(address _who) { require(_who != address(0)); _; }
    modifier notEmptyUint(uint _uint) { require(_uint != 0); _; }
    modifier notLocked() { require(!locked); _; }
}
