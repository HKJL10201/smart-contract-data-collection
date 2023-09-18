pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./lib/ITub.sol";
import "./lib/dappsys-monolithic/proxy.sol";

contract AuctionRegistry {
    enum AuctionState {
        Waiting,
        Live,
        Cancelled,
        Ended,
        Expired
    }

    struct AuctionInfo {
        uint256 listingNumber;
        bytes32 cdp;
        address seller;
        address proxy;
        address token;
        uint256 ask;
        bytes32 auctionId;
        uint256 expiryBlock;
        AuctionState state;
    }

    struct BidInfo {
        bytes32 cdp;
        bytes32 auctionId;
        address buyer;
        address proxy;
        uint256 value;
        address token;
        bytes32 bidId;
        uint256 expiryBlock;
        bool    won;
        bool    revoked;
    }

    uint256 public totalListings = 0;

    // Mapping of auctionIds to its corresponding CDP auction
    mapping (bytes32 => AuctionInfo) internal auctions;
    // Mapping for iterative lookup of all auctions
    mapping (uint256 => AuctionInfo) internal allAuctions;
    // Mapping of users to AuctionIds
    mapping (address => bytes32[]) internal userToAuctions;

    // Registry mapping bidIds to their corresponding entries
    mapping (bytes32 => BidInfo) internal bidRegistry;
    // Mapping of auctionIds to bidIds
    mapping (bytes32 => bytes32[]) internal auctionToBids;
    // Mapping of users to bidIds
    mapping (address => bytes32[]) internal userToBids;

    function getAuctionsByUser(address auctioneer)
        public
        view
        returns (bytes32[])
    {
        return userToAuctions[auctioneer];
    }

    function getAuctionInfo(bytes32 auctionId)
        public
        view
        returns (
            uint256 number,
            bytes32 cdp,
            address seller,
            address proxy,
            address token,
            uint256 ask,
            uint256 expiry,
            AuctionState state
        )
    {
        number = auctions[auctionId].listingNumber;
        cdp    = auctions[auctionId].cdp;
        seller = auctions[auctionId].seller;
        proxy  = auctions[auctionId].proxy;
        token  = auctions[auctionId].token;
        ask    = auctions[auctionId].ask;
        expiry = auctions[auctionId].expiryBlock;
        state  = auctions[auctionId].state;
    }

    function getAuctionInfoByIndex(uint256 index)
        public
        view
        returns (
            bytes32 id,
            bytes32 cdp,
            address seller,
            address proxy,
            address token,
            uint256 ask,
            uint256 expiry,
            AuctionState state
        )
    {
        id     = allAuctions[index].auctionId;
        cdp    = allAuctions[index].cdp;
        seller = allAuctions[index].seller;
        proxy  = allAuctions[index].proxy;
        token  = allAuctions[index].token;
        ask    = allAuctions[index].ask;
        expiry = allAuctions[index].expiryBlock;
        state  = allAuctions[index].state;
    }

    function getBids(bytes32 auctionId)
        public 
        view
        returns (bytes32[])
    {
        return auctionToBids[auctionId];
    }

    function getBidsByUser(address bidder)
        public
        view
        returns (bytes32[])
    {
        return userToBids[bidder];
    }

    function getBidInfo(bytes32 bidId)
        public
        view
        returns (
            bytes32 cdp,
            bytes32 auctionId,
            address buyer,
            address proxy,
            uint256 value,
            address token,
            uint256 expiry,
            bool    revoked,
            bool    won
        )
    {
        cdp       = bidRegistry[bidId].cdp;
        auctionId = bidRegistry[bidId].auctionId;
        buyer     = bidRegistry[bidId].buyer;
        proxy     = bidRegistry[bidId].proxy;
        value     = bidRegistry[bidId].value;
        token     = bidRegistry[bidId].token;
        expiry    = bidRegistry[bidId].expiryBlock;
        revoked   = bidRegistry[bidId].revoked;
        won       = bidRegistry[bidId].won;
    }
}

contract AuctionEvents is AuctionRegistry{
    event LogAuctionEntry(
        bytes32 cdp,
        address indexed seller,
        address indexed proxy,
        bytes32 indexed auctionId,
        address token,
        uint256 ask,
        uint256 expiry
    );

    event LogEndedAuction(
        bytes32 indexed auctionId,
        bytes32 cdp,
        address indexed seller,
        AuctionState state
    );

    event LogConclusion(
        bytes32 cdp,
        address seller,
        address buyer,
        bytes32 indexed auctionId,
        bytes32 indexed bidId,
        uint256 value
    );

    event LogSubmittedBid(
        bytes32 cdp,
        bytes32 indexed auctionId,
        address indexed buyer,
        address proxy,
        uint256 value,
        address token,
        bytes32 indexed bidId,
        uint256 expiryBlock
    );

    event LogRevokedBid(
        bytes32 cdp,
        address indexed buyer,
        bytes32 indexed bidId,
        uint256 value
    );

    event LogCDPTransfer(
        bytes32 indexed cdp,
        address indexed to
    );
}

contract Auction is Pausable, AuctionEvents{
    using SafeMath for uint256;

    address private feeTaker;
    uint256 public fee;
    ITub public tub;
    
    constructor(address _tub)
        public 
    {
        tub = ITub(_tub);
        feeTaker = msg.sender;
        fee = 0;
    }

    /**
     * List a CDP for auction
     */
    function listCDP(
        bytes32 cdp,
        address seller,
        address token,
        uint256 ask,
        uint256 expiry,
        uint256 salt
    )
        external
        whenNotPaused
        returns (bytes32)
    {
        require(tub.lad(cdp) != address(this), "cdp already on auction");
        require(DSProxy(msg.sender).owner() == seller, "proxy-seller mismatch");

        bytes32 auctionId = _genAuctionId(
            ++totalListings,
            cdp,
            msg.sender,
            expiry,
            salt
        );

        require(auctions[auctionId].auctionId == bytes32(0), "auctionId already used");

        AuctionInfo memory entry = AuctionInfo(
            totalListings,
            cdp,
            seller,
            msg.sender,
            token,
            ask,
            auctionId,
            expiry,
            AuctionState.Waiting
        );

        updateAuction(entry, AuctionState.Waiting);
        userToAuctions[seller].push(auctionId);

        emit LogAuctionEntry(
            cdp,
            seller,
            msg.sender,
            auctionId,
            token,
            ask,
            expiry
        );

        return auctionId;
    }

    /* Resolve auction by seller */
    function resolveAuction(bytes32 auctionId, bytes32 bidId)
        external 
    {
        AuctionInfo memory entry = auctions[auctionId];
        require(tub.lad(entry.cdp) == address(this), "cdp not owned by auction");
        require(entry.seller == msg.sender, "caller must be seller");
        require(entry.state == AuctionState.Live, "auction is not live");

        if(block.number >= entry.expiryBlock) {
            endAuction(entry, AuctionState.Expired);
            return;
        }

        BidInfo memory bid = bidRegistry[bidId];
        require(!bid.revoked, "bid was revoked");
        require(bid.value != 0, "bid value cannot be zero");
        require(block.number < bid.expiryBlock, "bid expired");
        bid.won = true;
        bidRegistry[bidId] = bid;

        concludeAuction(entry, bidId, bid.buyer, bid.proxy, bid.token, bid.value);
    }

    /* Remove a CDP from auction */
    function cancelAuction(bytes32 auctionId)
        external
    {
        AuctionInfo memory entry = auctions[auctionId];
        require(tub.lad(entry.cdp) == address(this), "cdp not owned by auction");
        require(entry.state == AuctionState.Waiting ||
                entry.state == AuctionState.Expired, "cannot cancel live auction");
        require(msg.sender == entry.seller, "caller must be seller");

        AuctionState state = (block.number >= entry.expiryBlock)
                                ? AuctionState.Expired
                                : AuctionState.Cancelled;
        endAuction(entry, state);
    }

    function submitBid(
        bytes32 auctionId,
        address proxy,
        address token,
        uint256 value,
        uint256 expiry,
        uint256 salt
    )
        external
        whenNotPaused
        returns (bytes32)
    {
        AuctionInfo memory entry = auctions[auctionId];
        require(tub.lad(entry.cdp) == address(this), "cdp not owned by auction");
        require(DSProxy(proxy).owner() == msg.sender, "proxy-bidder mismatch");
        require(
            entry.state == AuctionState.Live ||
            entry.state == AuctionState.Waiting, 
            "auction must be live"
        );
        
        if(block.number >= entry.expiryBlock) {
            endAuction(entry, AuctionState.Expired);
            return bytes32(0);
        }

        if(entry.state == AuctionState.Waiting) {
            updateAuction(entry, AuctionState.Live);
        }

        bytes32 bidId = _genBidId(
            auctionId,
            msg.sender,
            value,
            expiry % block.number,
            salt
        );

        require(bidRegistry[bidId].bidId == bytes32(0), "bidId already used");

        BidInfo memory bid = BidInfo(
            entry.cdp,
            auctionId,
            msg.sender,
            proxy,
            value,
            token,
            bidId,
            expiry,
            false,
            false
        );

        // Auction tokens held in escrow until bid expires
        IERC20(token).transferFrom(msg.sender, this, value);

        if(value >= entry.ask && token == entry.token) {
            // Allow auction to conclude if bid >= ask
            bid.won = true;
            concludeAuction(entry, bidId, msg.sender, proxy, entry.token, value);
        }

        bidRegistry[bidId] = bid;
        userToBids[msg.sender].push(bidId);
        auctionToBids[auctionId].push(bidId);

        emit LogSubmittedBid(
            entry.cdp,
            auctionId,
            msg.sender,
            proxy,
            value,
            token,
            bidId,
            expiry
        );

        return bidId;
    }

    function revokeBid(bytes32 bidId)
        external
    {
        BidInfo memory bid = bidRegistry[bidId];
        require(msg.sender == bid.buyer, "caller must be buyer");
        require(!bid.revoked, "bid already revoked");
        bid.revoked = true;
        bidRegistry[bidId] = bid;
        IERC20(bid.token).transfer(msg.sender, bid.value);

        emit LogRevokedBid(
            bid.cdp,
            msg.sender,
            bidId,
            bid.value
        );
    }

    function concludeAuction(
        AuctionInfo entry,
        bytes32 bidId,
        address winner, 
        address proxy, 
        address token,
        uint256 value
    ) 
        internal
    {
        uint256 service = value.mul(fee);
        IERC20(token).transfer(feeTaker, service);
        IERC20(token).transfer(entry.seller, value.sub(service));

        transferCDP(
            entry.cdp, 
            proxy,
            winner
        );

        updateAuction(entry, AuctionState.Ended);

        emit LogConclusion(
            entry.cdp,
            winner,
            entry.seller,
            entry.auctionId,
            bidId,
            value
        );
    }

    function endAuction(AuctionInfo entry, AuctionState state)
        internal
    {
        updateAuction(entry, state);
        transferCDP(
            entry.cdp,
            entry.proxy,
            entry.seller
        );

        emit LogEndedAuction(
            entry.auctionId,
            entry.cdp,
            entry.seller,
            state
        );
    }

    function updateAuction(AuctionInfo entry, AuctionState state)
        internal
    {
        entry.state = state;
        auctions[entry.auctionId] = entry;
        allAuctions[entry.listingNumber] = entry;
    }

    function transferCDP(
        bytes32 cdp, 
        address proxy, 
        address proxyOwner
    ) internal
    {
        require(DSProxy(proxy).owner() == proxyOwner, "sender-proxy mismatch");
        tub.give(cdp, proxy);

        emit LogCDPTransfer(
            cdp,
            proxy
        );
    }

    /**
     * Helper function for computing the hash of a given auction
     * listing. Will be used as the auctionId for each new CDP
     * auctions. 
     */
    function _genAuctionId(
        uint256 _auctionCounter,
        bytes32 _cup, 
        address _seller, 
        uint256 _expiry, 
        uint256 _salt
    )
        internal
        pure
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _auctionCounter,
                _cup, 
                _seller, 
                _expiry,
                _salt
            )
        );
    }

    /**
     * Helper function for computing the hash of a given bid.
     * Will be used as the bidId for each bid in an auction.
     */
    function _genBidId(
        bytes32 _auctionId,
        address _buyer,
        uint256 _value,
        uint256 _expiry,
        uint256 _salt
    ) 
        internal
        pure
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _auctionId,
                _buyer,
                _value,
                _expiry,
                _salt
            )
        );
    }

    function setFeeTaker(address newFeeTaker) 
        public
        onlyPauser
    {
        feeTaker = newFeeTaker;
    }

    function setFee(uint256 newFee) 
        public
        onlyPauser
    {
        fee = newFee;
    }
}