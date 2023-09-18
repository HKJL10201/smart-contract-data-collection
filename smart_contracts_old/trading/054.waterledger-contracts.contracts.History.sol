// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./QuickSort.sol";

contract History is QuickSort, Ownable {

    enum Status {Pending, Completed, Rejected, Invalid}

    struct Trade {
        bytes16 id;
        address buyer;
        address seller;
        uint256 averagePrice;
        uint256 quantity;
        uint256 timeStamp;
        bytes32 fromZone;
        bytes32 toZone;
        bytes16 orderId;
        Status status;
    }

    struct IndexPosition {
        uint256 index;
        bool isValid;
    }

    Trade[] public _history;
    mapping(address => bool) private _allowedWriters;

    mapping(bytes16 => IndexPosition) _idToIndex;

    constructor(address orderBook) {
        _allowedWriters[msg.sender] = true;
        _allowedWriters[orderBook] = true;
    }

    function getTrade(bytes16 id) public view guardId(id) returns (Trade memory) {
        return _history[_idToIndex[id].index];
    }

    function getTradeDetails(bytes16 id)
        public
        view
        guardId(id)
        returns (
            bytes16,
            address,
            address,
            uint256,
            uint256,
            bytes32,
            bytes32
        )
    {
        Trade memory trade = _history[_idToIndex[id].index];
        return (trade.orderId, trade.buyer, trade.seller, trade.averagePrice, trade.quantity, trade.fromZone, trade.toZone);
    }

    function getHistory(uint256 numberOfTrades) public view returns (Trade[] memory) {
        uint256 max = _history.length < numberOfTrades ? _history.length : numberOfTrades;

        if (max > 1000) {
            max = 1000;
        }

        uint256[] memory sortedIndexes = getTimeHistory();
        Trade[] memory returnedTrades = new Trade[](max);

        for (uint256 i = 0; i < max; i++) {
            returnedTrades[i] = _history[sortedIndexes[i]];
        }

        return returnedTrades;
    }

    function getLicenceHistory(address licenceAddress) public view returns (Trade[] memory) {
        uint256 max = getLicenceTradeCount(licenceAddress);
        Trade[] memory returnedTrades = new Trade[](max);

        uint256 currentIndex = 0;

        for (uint256 i; i < _history.length; i++) {
            if (_history[i].buyer == licenceAddress || _history[i].seller == licenceAddress) {
                returnedTrades[currentIndex] = _history[i];
                currentIndex++;
            }
        }

        return returnedTrades;
    }

    function getLicenceTradeCount(address licenceAddress) public view returns (uint256) {
        uint256 tradeCount = 0;
        for (uint256 i; i < _history.length; i++) {
            if (_history[i].buyer == licenceAddress || _history[i].seller == licenceAddress) {
                tradeCount++;
            }
        }
        return tradeCount;
    }

    function getTradeCount() public view returns (uint256) {
        return _history.length;
    }

    function getTimeHistory() internal view returns (uint256[] memory) {
        uint256[] memory timeStamps = new uint256[](_history.length);
        uint256[] memory indexes = new uint256[](_history.length);

        if (_history.length == 0) {
            return indexes;
        }

        for (uint256 i = 0; i < _history.length; i++) {
            timeStamps[i] = _history[i].timeStamp;
            indexes[i] = i;
        }

        uint256[] memory sortedIndexes = reverseSortWithIndex(timeStamps, indexes);
        return sortedIndexes;
    }

    function addHistory(
        address buyer,
        address seller,
        uint256 price,
        uint256 quantity,
        bytes32 fromZone,
        bytes32 toZone,
        bytes16 orderId
    ) external onlyWriters("Only writers can add history") {
        bytes16 id = createId(block.timestamp, price, quantity, buyer);

        _history.push(Trade(id, buyer, seller, price, quantity, block.timestamp, fromZone, toZone, orderId, Status.Pending));

        _idToIndex[id] = IndexPosition(_history.length - 1, true);

        emit HistoryAdded(id, buyer, seller, price, quantity, fromZone, toZone, orderId);
    }

    function createId(
        uint256 timestamp,
        uint256 price,
        uint256 quantity,
        address user
    ) public pure returns (bytes16) {
        return bytes16(keccak256(abi.encode(timestamp, price, quantity, user)));
    }

    function addManualHistory(
        address buyer,
        address seller,
        uint256 price,
        uint256 quantity,
        bytes32 fromZone,
        bytes32 toZone,
        bytes16 orderId,
        uint256 timestamp,
        Status status
    ) external onlyOwner {
        bytes16 id = createId(block.timestamp, price, quantity, buyer);
        _history.push(Trade(id, buyer, seller, price, quantity, timestamp, fromZone, toZone, orderId, status));
        _idToIndex[id] = IndexPosition(_history.length - 1, true);
        emit ManualHistoryAdded(id);
    }

    function rejectTrade(bytes16 id) public onlyOwner guardId(id) {
        _history[_idToIndex[id].index].status = Status.Rejected;
        emit TradeRejected(_history[_idToIndex[id].index].id);
    }

    function invalidateTrade(bytes16 id) public onlyWriters("Trade can only be invalidated by the orderbook") guardId(id) {
        _history[_idToIndex[id].index].status = Status.Invalid;
        emit TradeInvalidated(_history[_idToIndex[id].index].id);
    }

    function completeTrade(bytes16 id) public onlyWriters("Only writers can update history") guardId(id) {
        _history[_idToIndex[id].index].status = Status.Completed;
        emit TradeCompleted(id);
    }

    function addWriter(address who) public onlyOwner {
        _allowedWriters[who] = true;
    }

    function denyWriter(address who) public onlyOwner {
        _allowedWriters[who] = false;
    }

    modifier onlyWriters(string memory error) {
        require(_allowedWriters[msg.sender] == true, error);
        _;
    }

    modifier guardId(bytes16 id) {
        require(_idToIndex[id].isValid, "The ID provided is not valid");
        _;
    }

    event HistoryAdded(bytes16 id, address buyer, address seller, uint256 price, uint256 quantity, bytes32 fromZone, bytes32 toZone, bytes16 orderId);
    event ManualHistoryAdded(bytes16 id);
    event TradeCompleted(bytes16 id);
    event TradeInvalidated(bytes16 id);
    event TradeRejected(bytes16 id);
}
