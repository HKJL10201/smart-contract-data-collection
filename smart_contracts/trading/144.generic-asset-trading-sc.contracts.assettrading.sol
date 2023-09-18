pragma solidity >=0.4.22 <0.6.0;

contract AssetTrading {
    address public contractOwner;

    uint public lastOrderId = 0;
    uint public lastAssetId = 0;
    uint public defaultTxExpirationTime = 3600;
    uint internal nonce = 0;

    mapping (string => uint) public supportedAssets;
    mapping (uint => string) public idToSupportedAsset;
    mapping (uint => mapping(address => bool)) public watchers;
    mapping (uint => address[]) public watchersList;
    mapping (uint => Order) orders;
    mapping (uint => Trade) trades;
    mapping (uint => uint) private makerCollateral;
    mapping (uint => uint) private takerCollateral;

    struct Order {
        address creator;
        uint buyAmount;
        string buyType;
        uint sellAmount;
        string sellType;
        uint numWatchers;
        bool exists;
        bytes takerDestinationAddress;
    }

    struct Trade {
        Order order;
        address maker;
        address taker;
        address[] buyAssetWatchers;
        address[] sellAssetWatchers;
        uint64 timestamp;
        TradeState state;
        bytes makerDestinationAddress;
        bytes takerDestinationAddress;
    }

    enum TradeState {
        TakerResponsibility,
        MakerResponsibility
    }

    constructor() public {
        contractOwner = msg.sender;
        addSupportForAsset("BTC");
        addSupportForAsset("XRP");
    }

    /*
    Supported asset management
    */
    function addSupportForAsset(string memory asset) public {
        require(msg.sender == contractOwner);
        lastAssetId++;
        supportedAssets[asset] = lastAssetId;
        idToSupportedAsset[lastAssetId] = asset;
    }

    function removeSupportForAsset(string memory asset) public {
        require(msg.sender == contractOwner);
        delete supportedAssets[asset];

        // TODO remove all the orders with this asset
    }

    /*
    Order management
    */
    function makeOrder(uint buyAmount, string memory buyType, uint sellAmount, string memory sellType, uint numWatchers, bytes memory takerDestinationAddress) public payable returns (uint id) {
        // TODO checks!
        require(supportedAssets[buyType] != 0);
        require(supportedAssets[sellType] != 0);
        // make sure we buy/sell at least something.
        require(buyAmount > 0);
        require(sellAmount > 0);
        // make sure we have at least one watcher.
        require(numWatchers > 0);
        // watchers required by the order creator will act on the chain hosting the buying assets. Maker shre there are enough.
        require(watchersList[supportedAssets[buyType]].length >= numWatchers);
        // make sure we deposit collateral.
        // TODO: for now, this is fixed!
        require(msg.value >= 10000);
        // make sure we have a destination address
        require(takerDestinationAddress.length > 0);

        lastOrderId++;

        Order memory order;
        order.creator = msg.sender;
        order.buyAmount = buyAmount;
        order.buyType = buyType;
        order.sellAmount = sellAmount;
        order.sellType = sellType;
        order.numWatchers = numWatchers;
        order.exists = true;
        order.takerDestinationAddress = takerDestinationAddress;
        orders[lastOrderId] = order;

        makerCollateral[lastOrderId] = msg.value;

        return lastOrderId;
    }

    function cancelOrder(uint order_id) public {
        require(orders[order_id].creator == msg.sender);
        delete orders[order_id];
    }

    function takeOrder(uint order_id, uint numWatchers, bytes memory makerDestinationAddress) public payable {
        // check if the order exists
        require(orders[order_id].exists);
        Order memory order = orders[order_id];
        // the creator of this order will issue a transaction on the chain hosting sellAssets. Make sure there are enough watchers.
        require(watchersList[supportedAssets[order.sellType]].length >= numWatchers);
        // TODO: for now, this is fixed!
        require(msg.value >= 10000);

        // create a new trade
        Trade memory trade;
        trade.order = orders[order_id];
        trade.maker = order.creator;
        trade.taker = msg.sender;
        trade.timestamp = uint64(now);
        trade.makerDestinationAddress = makerDestinationAddress;
        trade.takerDestinationAddress = order.takerDestinationAddress;
        trades[order_id] = trade;

        // delete the order
        delete orders[order_id];

        takerCollateral[lastOrderId] = msg.value;

        // select watchers for both chains
        address[] memory allBuyAssetWatchers = watchersList[supportedAssets[order.buyType]];
        address[] memory allSellAssetWatchers = watchersList[supportedAssets[order.sellType]];

        uint buyAssetWatcherIndex = random(allBuyAssetWatchers.length);
        uint sellAssetWatcherIndex = random(allSellAssetWatchers.length);
        // TODO: for now, just select everyone as watcher
        for(uint i = 0; i < allBuyAssetWatchers.length; i++) {
            trades[order_id].buyAssetWatchers.push(allBuyAssetWatchers[i]);
        }
        for(uint i = 0; i < allSellAssetWatchers.length; i++) {
            trades[order_id].sellAssetWatchers.push(allSellAssetWatchers[i]);
        }
    }

    /*
    Watcher management
    */
    function registerAsWatcher(uint[] memory watchingAssets) public {
        for(uint i = 0; i < watchingAssets.length; i++) {
            uint assetId = watchingAssets[i];
            // check if the asset type exists
            require(bytes(idToSupportedAsset[assetId]).length > 0);
            // check if this user is not already watching this asset
            require(!watchers[assetId][msg.sender]);
            watchers[assetId][msg.sender] = true;
            watchersList[assetId].push(msg.sender);
        }
        // TODO collateral?
    }

    // TODO remove watcher?

    /*
    Collateral management
    */
    function claimMakerCollateral(uint order_id) public {
        // can we claim it?
        require(now >= trades[order_id].timestamp + 1 hours);
        // is the trade in the right state?
        require(trades[order_id].state == TradeState.MakerResponsibility);
        // are we the taker?
        require(msg.sender == trades[order_id].taker);

        uint amount = makerCollateral[order_id];
        makerCollateral[order_id] = 0;
        msg.sender.transfer(amount);

        // cleanup the trade
        delete trades[order_id];

        // TODO reward watchers???
    }

    function claimTakerCollateral(uint order_id) public {
        // can we claim it?
        require(now >= trades[order_id].timestamp + 1 hours);
        // is the trade in the right state?
        require(trades[order_id].state == TradeState.TakerResponsibility);
        // are we the maker?
        require(msg.sender == trades[order_id].maker);

        uint amount = takerCollateral[order_id];
        takerCollateral[order_id] = 0;
        msg.sender.transfer(amount);

        // cleanup the trade
        delete trades[order_id];
    }

    /*
    Trade management
    */
    function proveTransfer(uint order_id) public {
        // check if the trade exists
        require(trades[order_id].timestamp != 0);
        // check if we are either the taker or the maker, and the trade is in the right state
        require((msg.sender == trades[order_id].taker && trades[order_id].state == TradeState.TakerResponsibility) || 
                (msg.sender == trades[order_id].maker && trades[order_id].state == TradeState.MakerResponsibility));

        if(msg.sender == trades[order_id].taker && trades[order_id].state == TradeState.TakerResponsibility) {
            trades[order_id].state = TradeState.MakerResponsibility;
            trades[order_id].timestamp = uint64(now);
        }
        else if(msg.sender == trades[order_id].maker && trades[order_id].state == TradeState.MakerResponsibility) {
            // done, cleanup trade
            delete trades[order_id];
        }

        // TODO: include signatures of watchers!
    }

    /*
    Utilities
    */
    function random(uint maxNumber) internal returns (uint) {
        // WARNING: we are aware that this is not a secure mechanism to generate random numbers!
        // To improve this, we should use an on-chain oracle.
        // For now, however, we use this method for uint testing.
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % maxNumber;
        nonce++;
        return randomnumber;
    }

}
