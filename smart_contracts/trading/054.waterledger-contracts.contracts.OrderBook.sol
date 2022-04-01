// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Zones.sol";
import "./History.sol";
import "./Licences.sol";

contract OrderBook is Ownable {
    string[] private _zoneNames;
    History private _history;
    Licences private _licences;
    Zones private _zones;
    uint256 private _year;

    uint256 private _lastTradedPrice;

    struct IndexPosition {
        uint256 index;
        bool isValid;
    }

    mapping(bytes16 => IndexPosition) private _idToIndex;

    enum OrderType {Sell, Buy}

    struct Order {
        bytes16 id;
        OrderType orderType;
        address owner;
        uint256 price;
        uint256 quantity;
        uint256 timeStamp;
        uint256 matchedTimeStamp;
        bytes32 zone;
    }

    Order[] private _orders;

    bytes16[] private _unmatchedBuys;
    bytes16[] private _unmatchedSells;

    string private _scheme;

    constructor(string memory scheme, uint256 year) Ownable() {
        _scheme = scheme;
        _year = year;
    }

    function addHistoryContract(address historyContract) public onlyOwner {
        _history = History(historyContract);
    }

    function getOrderById(bytes16 id) public view guardId(id) returns (Order memory) {
        return _orders[_idToIndex[id].index];
    }

    function addLicencesContract(address licencesContract) public onlyOwner {
        _licences = Licences(licencesContract);
    }

    function addZonesContract(address zonesContract) public onlyOwner {
        _zones = Zones(zonesContract);
    }

    function completeTrade(bytes16 tradeId) public onlyOwner {
        (, address buyer, , , uint256 quantity, , bytes32 toZone) = _history.getTradeDetails(tradeId);

        bytes32 waterAccountId = _licences.getWaterAccountIdByAddressAndZone(buyer, toZone);

        _history.completeTrade(tradeId);
        _zones.credit(toZone, waterAccountId, quantity);
    }

    function getLastTradedPrice() public view returns (uint256) {
        return _lastTradedPrice;
    }

    function getScheme() external view returns (string memory) {
        return _scheme;
    }

    function getYear() external view returns (uint256) {
        return _year;
    }

    function createId(
        uint256 timestamp,
        uint256 price,
        uint256 quantity,
        address user
    ) private pure returns (bytes16) {
        return bytes16(keccak256(abi.encode(timestamp, price, quantity, user)));
    }

    function removeUnmatchedSellId(bytes32 id) internal {
        for (uint256 i = 0; i < _unmatchedSells.length; i++) {
            if (_unmatchedSells[i] == id) {
                if (i != _unmatchedSells.length - 1) {
                    _unmatchedSells[i] = _unmatchedSells[_unmatchedSells.length - 1];
                }
                _unmatchedSells.pop();
            }
        }
    }

    function removeUnmatchedBuyId(bytes32 id) internal {
        for (uint256 i = 0; i < _unmatchedBuys.length; i++) {
            if (_unmatchedBuys[i] == id) {
                if (i != _unmatchedBuys.length - 1) {
                    _unmatchedBuys[i] = _unmatchedBuys[_unmatchedBuys.length - 1];
                }
                _unmatchedBuys.pop();
            }
        }
    }

    function addSellLimitOrder(
        uint256 price,
        uint256 quantity,
        bytes32 zone
    ) external {
        require(quantity > 0 && price > 0, "Values must be greater than 0");
        bytes32 waterAccountId = _licences.getWaterAccountIdByAddressAndZone(msg.sender, zone);
        require(_zones.getBalanceForZone(waterAccountId, zone) >= quantity, "Insufficient water allocation");
        bytes16 id = addOrder(price, quantity, zone, OrderType.Sell);
        _zones.debit(zone, waterAccountId, quantity);
        _unmatchedSells.push(id);
    }

    function addBuyLimitOrder(
        uint256 price,
        uint256 quantity,
        bytes32 zone
    ) external {
        require(quantity > 0 && price > 0, "Values must be greater than 0");
        bytes16 id = addOrder(price, quantity, zone, OrderType.Buy);
        _unmatchedBuys.push(id);
    }

    function addOrder(
        uint256 price,
        uint256 quantity,
        bytes32 zone,
        OrderType orderType
    ) internal returns (bytes16) {
        require(_licences.hasValid(msg.sender), "Sender has no valid licence");
        bytes16 id = createId(block.timestamp, price, quantity, msg.sender);
        _orders.push(Order(id, orderType, msg.sender, price, quantity, block.timestamp, 0, zone));
        _idToIndex[id] = IndexPosition(_orders.length - 1, true);
        emit OrderAdded(id, msg.sender, price, quantity, zone, orderType);
        return id;
    }

    function acceptOrder(bytes16 id, bytes32 zone) public guardId(id) {
        require(_licences.hasValid(msg.sender), "Sender has no valid licence");
        Order storage order = _orders[_idToIndex[id].index];
        require(order.owner != msg.sender, "You cannot accept your own order");

        order.matchedTimeStamp = block.timestamp;

        _lastTradedPrice = order.price;

        bytes32 toZone = order.orderType == OrderType.Sell ? zone : order.zone;
        bytes32 fromZone = order.orderType == OrderType.Sell ? order.zone : zone;

        address buyer = order.orderType == OrderType.Sell ? msg.sender : order.owner;
        address seller = order.orderType == OrderType.Sell ? order.owner : msg.sender;

        bool isToValid = _zones.isToTransferValid(toZone, order.quantity);
        bool isFromValid = _zones.isToTransferValid(fromZone, order.quantity);

        require(toZone == fromZone || (isToValid && isFromValid), "Transfer volumes are not valid");

        if (order.orderType == OrderType.Sell) {
            removeUnmatchedSellId(id);
        } else {
            removeUnmatchedBuyId(id);
        }

        _history.addHistory(buyer, seller, order.price, order.quantity, fromZone, toZone, order.id);

        emit OrderAccepted(id, msg.sender);
    }

    function getOrderBookSells() public view returns (Order[] memory) {
        return getOrders(_unmatchedSells);
    }

    function getOrderBookBuys() public view returns (Order[] memory) {
        return getOrders(_unmatchedBuys);
    }

    function getOrders(bytes16[] storage ids) internal view returns (Order[] memory) {
        Order[] memory returnedOrders = new Order[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            returnedOrders[i] = _orders[_idToIndex[ids[i]].index];
        }

        return returnedOrders;
    }

    function deleteOrder(bytes16 id) external guardId(id) {
        Order memory order = _orders[_idToIndex[id].index];
        require(order.owner != address(0), "This order does not exist");
        require(order.owner == msg.sender, "You can only delete your own order");
        require(order.matchedTimeStamp == 0, "This order has been matched");
        delete _orders[_idToIndex[id].index];

        bytes32 waterAccountId = _licences.getWaterAccountIdByAddressAndZone(order.owner, order.zone);

        if (order.orderType == OrderType.Sell) {
            removeUnmatchedSellId(order.id);
            _zones.credit(order.zone, waterAccountId, order.quantity);
        } else {
            removeUnmatchedBuyId(order.id);
        }

        emit OrderDeleted(order.id);
    }

    function getLicenceUnmatchedSellsCount(address licenceAddress) internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _unmatchedSells.length; i++) {
            Order memory order = _orders[_idToIndex[_unmatchedSells[i]].index];
            if (order.matchedTimeStamp == 0 && order.owner == licenceAddress) {
                count++;
            }
        }
        return count;
    }

    function getLicenceUnmatchedBuysCount(address licenceAddress) internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _unmatchedBuys.length; i++) {
            Order memory order = _orders[_idToIndex[_unmatchedBuys[i]].index];
            if (order.matchedTimeStamp == 0 && order.owner == licenceAddress) {
                count++;
            }
        }

        return count;
    }

    modifier guardId(bytes16 id) {
        require(_idToIndex[id].isValid, "The ID provided is not valid");
        _;
    }

    event OrderDeleted(bytes16 id);
    event OrderUnmatched(bytes16 orderId);
    event OrderAccepted(bytes16 orderId, address indexed buyer);
    event OrderAdded(bytes16 id, address indexed licenceAddress, uint256 price, uint256 quantity, bytes32 zone, OrderType orderType);
}
