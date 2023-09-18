// Dependency file: @openzeppelin/contracts/GSN/Context.sol

//  

// pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Dependency file: @openzeppelin/contracts/utils/Address.sol

//  

// pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * // importANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// Dependency file: @openzeppelin/contracts/utils/Pausable.sol

//  

// pragma solidity ^0.6.0;

// import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// Dependency file: @openzeppelin/contracts/access/Ownable.sol

//  

// pragma solidity ^0.6.0;

// import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

//  

// pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 //  
pragma solidity >=0.6.2 <0.7.0;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Pausable.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

interface ERC20Interface {
    function balanceOf(address from) external view returns (uint256);
    function transferFrom(address from, address to, uint tokens) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface ERC721Interface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function supportsInterface(bytes4) external view returns (bool);
}

interface ERC721Verifiable is ERC721Interface {
    function verifyFingerprint(uint256, bytes memory) external view returns (bool);
}


contract TrustAuction is Pausable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    event AuctionCreated(
        uint256 id,
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 expiresAt,
        bytes fingerprint
    );

    event AuctionBided(
        uint256 id,
        address seller,
        address indexed bidder,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 expiresAt
    );

    event AuctionFilled(
        uint256 id,
        address seller,
        address indexed bidder,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 expiresAt
    );

    event AuctionClosed(
        uint256 id,
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 expiresAt,
        bytes fingerprint
    );

    event ChangedOwnerCutPerMillion(uint256 _ownerCutPerMillion);

    uint256 public constant MAX_BID_DURATION = 182 days;
    //uint256 public constant MIN_BID_DURATION = 1 minutes;
    uint256 public constant MIN_BID_DURATION = 1 seconds;
    uint256 public constant ONE_MILLION = 1000000;
    bytes4 public constant ERC721_Interface = 0x80ac58cd;
    bytes4 public constant ERC721_Received = 0x150b7a02;
    bytes4 public constant ERC721Composable_ValidateFingerprint = 0x8f9f4b63;

    uint256 public ownerCutPerMillion;

    // usdt
    ERC20Interface public usdtToken;

    struct Auction {
        // auction id
        uint256 id;
        // seller 
        address seller;
        // highest bidder
        address bidder;
        // ERC721 address
        address tokenAddress;
        // ERC721 token id
        uint256 tokenId;
        // price of the current bid, in wei
        uint256 price;
        // time when this auction end
        uint256 expiresAt;

        AuctionStatus status;
        // Fingerprint for composable
        bytes fingerprint;
    }

    enum AuctionStatus {
        Live,
        Filled,
        Closed
    }


    // ERC721 address => global auction id
    mapping(address => uint256) public globalAuctionId;
    // ERC721 address => token id => index
    mapping(address => mapping(uint256 => uint256)) auctionIndex;
    // ERC721 address => index => auction
    mapping(address => mapping(uint256 => Auction)) globalAuction;

    // ERC721 address => tokenid => auction id
    mapping(address => mapping(uint256 => uint256)) public auctionId;
    // ERC721 address => token id => auction flag
    mapping(address => mapping(uint256 => bool)) private hasAuction;
    // ERC721 address => token id => auction
    mapping(address => mapping(uint256 => Auction)) private auctionByTokenId;
    // ERC721 address => auction id => auction
    mapping(address => mapping(uint256 => Auction)) private auctionByAuctionId;

    // token address => token id => owner 
    mapping(address => mapping(uint256 => address)) ownerByTokenId;



    modifier onlyCreator(address _tokenAddress, uint256 _tokenId) {
        require(ownerByTokenId[_tokenAddress][_tokenId] == msg.sender, "Ownable: caller is not the creator");
        _;
    }


    constructor(address _usdtToken) Ownable() Pausable() public {
        usdtToken = ERC20Interface(_usdtToken);
    }


    function createAuction(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration
    ) public {
        _createAuction(_tokenAddress, _tokenId, _price, _duration, "");
    }

    function createAuction(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration,
        bytes memory _fingerprint
    ) public {
        _createAuction(_tokenAddress, _tokenId, _price, _duration, _fingerprint);
    }

    function _createAuction(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration,
        bytes memory _fingerprint
    ) private whenNotPaused() {
        _requireERC721(_tokenAddress);
        _requireComposableERC721(_tokenAddress, _tokenId, _fingerprint);

        require(_price > 0, "Price should be bigger than 0");
        require(_duration >= MIN_BID_DURATION 
            && _duration <= MAX_BID_DURATION, "The bid duration error");
        require(!hasAuction[_tokenAddress][_tokenId]);

        uint256 _auctionId = auctionId[_tokenAddress][_tokenId];  // ? bug

        Auction memory auction = Auction({
            id: _auctionId,
            seller: msg.sender,
            bidder: address(0),
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            price: _price,
            expiresAt: block.timestamp.add(_duration),
            status: AuctionStatus.Live,
            fingerprint: _fingerprint
        });

        auctionByTokenId[_tokenAddress][_tokenId] = auction;
        auctionByAuctionId[_tokenAddress][_auctionId] = auction;

        auctionId[_tokenAddress][_tokenId]++;

        hasAuction[_tokenAddress][_tokenId] = true;

        ownerByTokenId[_tokenAddress][_tokenId] = msg.sender;
        _stake(_tokenAddress, _tokenId);  //deposit in

        // add global data reference
        uint256 index = globalAuctionId[_tokenAddress];
        globalAuction[_tokenAddress][index] = auction;

        auctionIndex[_tokenAddress][_tokenId] = globalAuctionId[_tokenAddress];

        globalAuctionId[_tokenAddress]++;


        emit AuctionCreated(
            _auctionId,
            msg.sender,
            _tokenAddress,
            _tokenId,
            _price,
            _duration,
            _fingerprint
        );
    }

    function getAuctionCount(address _tokenAddress) public view returns (uint256) {
        return globalAuctionId[_tokenAddress];
    }

    function getAuctionByIndex(address _tokenAddress, uint256 _index) public view 
        returns (
            uint256 id,
            address seller,
            address bidder,
            address tokenAddress,
            uint256 tokenId,
            uint256 price,
            AuctionStatus status,
            uint256 expiresAt
        )
    {
        require(_index < globalAuctionId[_tokenAddress], 'auction index error');
        Auction memory auction = globalAuction[_tokenAddress][_index];
        return (
            auction.id,
            auction.seller,
            auction.bidder,
            auction.tokenAddress,
            auction.tokenId,
            auction.price,
            auction.status,
            auction.expiresAt
        );
    }

    function getAuctionByTokenId(address _tokenAddress, uint256 _tokenId) public view 
        returns (
            uint256 id,
            address seller,
            address bidder,
            address tokenAddress,
            uint256 tokenId,
            uint256 price,
            AuctionStatus status,
            uint256 expiresAt
        )
    {
        Auction memory auction = auctionByTokenId[_tokenAddress][_tokenId];
        return (
            auction.id,
            auction.seller,
            auction.bidder,
            auction.tokenAddress,
            auction.tokenId,
            auction.price,
            auction.status,
            auction.expiresAt
        );
    }

    function getAuctionByAuctionId(address _tokenAddress, uint256 _auctionId) public view 
        returns (
            uint256 id,
            address seller,
            address bidder,
            address tokenAddress,
            uint256 tokenId,
            uint256 price,
            uint256 expiresAt
        )
    {
        Auction memory auction = auctionByAuctionId[_tokenAddress][_auctionId];
        return (
            auction.id,
            auction.seller,
            auction.bidder,
            auction.tokenAddress,
            auction.tokenId,
            auction.price,
            auction.expiresAt
        );
    }


    function bidAuction(address _tokenAddress, uint256 _tokenId, uint256 _price) public {
        Auction memory auction = auctionByTokenId[_tokenAddress][_tokenId];

        require(_price > auction.price, 'BidAuction: price should be big than current price');
        require(block.timestamp < auction.expiresAt);

        _requireBidderBalance(msg.sender, _price);

        // update price and high bidder
        auction.price = _price;
        auction.bidder = msg.sender;

        uint256 index = auctionIndex[_tokenAddress][_tokenId];
        globalAuction[_tokenAddress][index] = auction;

        auctionByTokenId[_tokenAddress][_tokenId] = auction;
        auctionByAuctionId[_tokenAddress][auction.id] = auction;

        emit AuctionBided(
            auction.id,
            auction.seller,
            msg.sender,
            auction.tokenAddress,
            auction.tokenId,
            _price,
            auction.expiresAt
        );
    }

    function finishAuction(address _tokenAddress, uint256 _tokenId) public {
        Auction memory auction = auctionByTokenId[_tokenAddress][_tokenId];

        require(auction.expiresAt < block.timestamp);
        require(auction.bidder == msg.sender, "FinishAuction: you are not the highest bidder");

        _requireBidderBalance(msg.sender, auction.price);

        uint256 saleShareAmount = 0;
        if (ownerCutPerMillion > 0) {
            saleShareAmount = auction.price.mul(ownerCutPerMillion).div(ONE_MILLION);

            require(usdtToken.transferFrom(auction.bidder, owner(), saleShareAmount),
                "Transfering the cut to the bid contract owner failed"
            );
        }

        require(usdtToken.transferFrom(auction.bidder, auction.seller, auction.price.sub(saleShareAmount)),
            "Transfering USDT to owner failed"
        );

        ERC721Interface(_tokenAddress).transferFrom(address(this), msg.sender, _tokenId);

        auction.status = AuctionStatus.Filled;
        auctionByAuctionId[_tokenAddress][auction.id] = auction;

        uint256 index = auctionIndex[_tokenAddress][_tokenId];
        globalAuction[_tokenAddress][index] = auction;


        hasAuction[_tokenAddress][_tokenId] = false;
        delete auctionByTokenId[_tokenAddress][_tokenId];
        delete ownerByTokenId[_tokenAddress][_tokenId];    // clear the owner

        emit AuctionFilled(
            auction.id,
            auction.seller,
            auction.bidder,
            _tokenAddress,
            _tokenId,
            auction.price,
            auction.expiresAt
        );
    }

    /**
    */
    function closeAuction(address _tokenAddress, uint256 _tokenId) onlyCreator(_tokenAddress, _tokenId)
        public whenNotPaused() {
        require(ownerByTokenId[_tokenAddress][_tokenId] == msg.sender);
        Auction memory auction = auctionByTokenId[_tokenAddress][_tokenId];

        auction.status = AuctionStatus.Closed;
        auctionByAuctionId[_tokenAddress][auction.id] = auction;

        hasAuction[_tokenAddress][_tokenId] = false;
        delete auctionByTokenId[_tokenAddress][_tokenId];
        delete ownerByTokenId[_tokenAddress][_tokenId];    // clear the owner

        uint256 index = auctionIndex[_tokenAddress][_tokenId];

        globalAuction[_tokenAddress][index] = auction;

        _widthdraw(_tokenAddress, _tokenId);

        emit AuctionClosed(
            auction.id,
            auction.seller,
            auction.tokenAddress,
            auction.tokenId,
            auction.price,
            auction.expiresAt,
            auction.fingerprint
        );
    }

    /**
    * @dev Sets the share cut for the owner of the contract that's
    * charged to the seller on a successful sale
    * @param _ownerCutPerMillion - Share amount, from 0 to 999,999
    */
    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) external onlyOwner {
        require(_ownerCutPerMillion < ONE_MILLION, "The owner cut should be between 0 and 999,999");

        ownerCutPerMillion = _ownerCutPerMillion;
        emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
    }


    // get a owner of a tokenid bid
    function getOwnerByTokenId(address _tokenAddress, uint256 _tokenId) public view returns (address) {
        return ownerByTokenId[_tokenAddress][_tokenId];
    }



    function _stake(address _tokenAddress, uint256 _tokenId) internal {
        ERC721Interface(_tokenAddress).transferFrom(msg.sender, address(this), _tokenId);
        ownerByTokenId[_tokenAddress][_tokenId] = msg.sender;
    }

    function _widthdraw(address _tokenAddress, uint256 _tokenId) internal {
        ERC721Interface(_tokenAddress).transferFrom(address(this), msg.sender, _tokenId);
        delete ownerByTokenId[_tokenAddress][_tokenId];
    }

    /**
    * @dev Check if the token has a valid ERC721 implementation
    * @param _tokenAddress - address of the token
    */
    function _requireERC721(address _tokenAddress) internal view {
        require(_tokenAddress.isContract(), "Token should be a contract");

        ERC721Interface token = ERC721Interface(_tokenAddress);
        require(
            token.supportsInterface(ERC721_Interface),
            "Token has an invalid ERC721 implementation"
        );
    }

    /**
    * @dev Check if the token has a valid Composable ERC721 implementation
    * And its fingerprint is valid
    * @param _tokenAddress - address of the token
    * @param _tokenId - uint256 of the index
    * @param _fingerprint - bytes of the fingerprint
    */
    function _requireComposableERC721(
        address _tokenAddress,
        uint256 _tokenId,
        bytes memory _fingerprint
    )
        internal
        view
    {
        ERC721Verifiable composableToken = ERC721Verifiable(_tokenAddress);
        if (composableToken.supportsInterface(ERC721Composable_ValidateFingerprint)) {
            require(
                composableToken.verifyFingerprint(_tokenId, _fingerprint),
                "Token fingerprint is not valid"
            );
        }
    }

    /**
    * @dev Check if the bidder has balance and the contract has enough allowance
    * to use bidder USDT on his belhalf
    * @param _bidder - address of bidder
    * @param _amount - uint256 of amount
    */
    function _requireBidderBalance(address _bidder, uint256 _amount) internal view {
        require(
            usdtToken.balanceOf(_bidder) >= _amount,
            "Insufficient funds"
        );
        require(
            usdtToken.allowance(_bidder, address(this)) >= _amount,
            "The contract is not authorized to use USDT on bidder behalf"
        );        
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}