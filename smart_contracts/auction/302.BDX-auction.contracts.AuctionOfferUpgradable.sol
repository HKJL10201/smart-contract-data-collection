// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/**
 *
 *       ,---,.     ,---,    ,--,     ,--,
 *     ,'  .'  \  .'  .' `\  |'. \   / .`|
 *   ,---.' .' |,---.'     \ ; \ `\ /' / ;
 *   |   |  |: ||   |  .`\  |`. \  /  / .'
 *   :   :  :  /:   : |  '  | \  \/  / ./
 *   :   |    ; |   ' '  ;  :  \  \.'  /
 *   |   :     \'   | ;  .  |   \  ;  ;
 *   |   |   . ||   | :  |  '  / \  \  \
 *   '   :  '; |'   : | /  ;  ;  /\  \  \
 *   |   |  | ; |   | '` ,/ ./__;  \  ;  \
 *   |   :   /  ;   :  .'   |   : / \  \  ;
 *   |   | ,'   |   ,.'     ;   |/   \  ' |
 *   `----'     '---'       `---'     `--`
 *  BDX General Bids
 *  All of the size unit is GiB
 */

interface IFactory {
    function hasAuction(address _addr) external returns (bool);
}

interface IAuction {
    function size() external view returns (uint256);

    function price() external view returns (uint256);

    function client() external view returns (address);

    function offerBid(address _addr, uint256 _payment) external returns (bool);
}

enum OfferStatus {
    Active,
    Cancelled
}
enum OfferType {
    Single,
    Multiple
}

struct Deal {
    uint256 price;
    uint256 size; // unit: GiB
    uint256 createTime; // unit: second
    address bidder;
    address auction;
    uint256 offerId;
}

struct BidOffer {
    uint256 id;
    address owner;
    uint256 totalValue;
    uint256 totalSize;
    uint256 minSize;
    uint256 validValue;
    uint256 validSize;
    uint256 createTime;
    OfferStatus status;
    OfferType offerType;
}

contract BigDataExchangeOfferUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable {
     using CountersUpgradeable for CountersUpgradeable.Counter;
 
    CountersUpgradeable.Counter private _offerId;
    IERC20 public token;

    address[] public factorys;
    address[] public dealsList;
    mapping(uint256 => BidOffer) public bidOffers;
    mapping(address => Deal) public deals;
    mapping(address => bool) public _isBlacklisted;
    bool internal _running;

    uint256[50] private _gap;

    event OfferCreated(uint256 indexed id, address indexed owner);

    event OfferCancelled(uint256 indexed id, address indexed sender);
    event OfferAccepted(
        uint256 indexed id,
        address indexed owner,
        address indexed auction
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _token) initializer public {
        require(_token != address(0), "invalid _token");
        __Ownable_init();
        __UUPSUpgradeable_init();
        token = IERC20(_token);
    }

    function setFactory(address[] memory _addrs) public onlyOwner {
        factorys = _addrs;
    }

    function createOffer(
        uint256 _price,
        uint256 _size,
        uint256 _minSize,
        OfferType _type
    ) public {
        require(_price > 0, "value not > 0");
        require(_size > 0, "size not > 0");
        require(token.balanceOf(msg.sender) >= _price, "balance not enough");
        require(!_isBlacklisted[msg.sender], "blacklisted address");
        require(
            token.allowance(msg.sender, address(this)) >= _price,
            "allowance not enough"
        );
        BidOffer storage g = bidOffers[_offerId.current()];
        g.id = _offerId.current();
        _offerId.increment();
        g.owner = msg.sender;
        g.status = OfferStatus.Active;
        g.totalSize = _size;
        g.totalValue = _price;
        g.minSize = _minSize;
        g.validValue = _price;
        g.validSize = _size;
        g.offerType = _type;
        g.createTime = block.timestamp;
        emit OfferCreated(_offerId.current() - 1, msg.sender);
    }

    function cancelOffer(uint256 _id) external {
        BidOffer storage g = bidOffers[_id];
        require(
            msg.sender == g.owner || msg.sender == owner(),
            "not owner or admin"
        );
        require(g.status == OfferStatus.Active, "status not active");
        g.status = OfferStatus.Cancelled;
        emit OfferCancelled(_id, msg.sender);
    }

    function bidOffer(address _auction, uint256 _offId) external nonReentrance {
        require(isValidAuction(_auction), "unvalid auction");
        BidOffer storage offer = bidOffers[_offId];
        require(offer.status == OfferStatus.Active, "status not active");
        IAuction au = IAuction(_auction);
        require(au.client() == msg.sender, "invalid client");
        uint256 size = au.size();
        require(size <= offer.validSize, "size not enough");
        require(size >= offer.minSize, "size invalid");
        uint256 payCount = getPayCont(offer.totalValue, offer.totalSize, size);
        require(
            token.transferFrom(offer.owner, _auction, payCount),
            "pay failed"
        );
        au.offerBid(offer.owner, payCount);
        Deal memory deal = Deal(
            payCount,
            size,
            block.timestamp,
            offer.owner,
            _auction,
            _offId
        );
        dealsList.push(_auction);
        deals[_auction] = deal;
        if (offer.offerType == OfferType.Single) {
            offer.status = OfferStatus.Cancelled;
        }
        offer.validValue -= payCount;
        offer.validSize -= size;
        emit OfferAccepted(_offId, offer.owner, _auction);
    }

    function setBlacklist(address _addr, bool _isBlacklist) external onlyOwner {
        _isBlacklisted[_addr] = _isBlacklist;
    }

    function isValidAuction(address _addr) internal returns (bool) {
        for (uint256 i = 0; i < factorys.length; i++) {
            address fc = factorys[i];
            if (IFactory(fc).hasAuction(_addr)) return true;
        }
        return false;
    }

    // helper
    function getPayCont(uint256 totalPrice, uint256 totalSize, uint256 _paySize) public pure returns (uint256) {
        return
            (((totalPrice * 100 * _paySize) / 1000000000000000000 / totalSize) * 1000000000000000000) / 100;
    }

    modifier nonReentrance() {
        require(!_running, "ReentrancyGuard: reentrant call");
        _running = true;
        _;
        _running = false;
    }

    // getter functions
    function getOfferCount() public view returns (uint256) {
        return _offerId.current();
    }

    function getOffers() public view returns (BidOffer[] memory) {
        BidOffer[] memory offerArray = new BidOffer[](_offerId.current());
        for (uint256 i = 0; i < _offerId.current(); i++) {
            BidOffer storage offer = bidOffers[i];
            offerArray[i] = offer;
        }
        return offerArray;
    }

    function getDeals() public view returns (Deal[] memory) {
        Deal[] memory dealArray = new Deal[](dealsList.length);
        for (uint256 i = 0; i < dealsList.length; i++) {
            Deal storage dl = deals[dealsList[i]];
            dealArray[i] = dl;
        }
        return dealArray;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

}