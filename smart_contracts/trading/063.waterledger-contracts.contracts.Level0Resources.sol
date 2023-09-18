// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./OrderBook.sol";

contract Level0Resources is Ownable {
    struct Level0Resource {
        bytes32 identifier;
        bool level0ResourceExists;
        uint256 supply;
        uint256 min;
        uint256 max;
    }

    mapping(bytes32 => Level0Resource) private level0Resources;
    OrderBook private immutable _orderbook;

    bytes32[] private level0ResourceList;

    mapping(bytes32 => mapping(bytes32 => uint256)) private balances;

    constructor(address orderbook) Ownable() {
        _orderbook = OrderBook(orderbook);
    }

    function getLevel0ResourceList() public view returns (bytes32[] memory) {
        return level0ResourceList;
    }

    function getLevel0Resources() public view returns (Level0Resource[] memory) {
        Level0Resource[] memory level0ResourcesArray = new Level0Resource[](level0ResourceList.length);
        uint256 count = level0ResourceList.length;
        for (uint8 i = 0; i < count; i++) {
            level0ResourcesArray[i] = level0Resources[level0ResourceList[i]];
        }
        return level0ResourcesArray;
    }

    function addLevel0Resource(
        bytes32 identifier,
        uint256 supply,
        uint256 min,
        uint256 max
    ) public onlyOwner {
        level0Resources[identifier] = Level0Resource(identifier, true, supply, min, max);
        level0ResourceList.push(identifier);
    }

    function addAllLevel0Resources(
        bytes32[] memory identifiers,
        uint256[] memory supplies,
        uint256[] memory mins,
        uint256[] memory maxes
    ) public onlyOwner {
        uint256 count = identifiers.length;
        for (uint8 i = 0; i < count; i++) {
            level0Resources[identifiers[i]] = Level0Resource(identifiers[i], true, supplies[i], mins[i], maxes[i]);
            level0ResourceList.push(identifiers[i]);
        }
        _orderbook.triggerLevel0ResourcesAdded();
    }

    function allocate(
        bytes32 identifier,
        bytes32 waterAccountId,
        uint256 quantity
    ) public onlyOwner {
        require(level0Resources[identifier].level0ResourceExists, "This level0Resource is not valid");
        balances[identifier][waterAccountId] = quantity;
        _orderbook.triggerAllocation(identifier, waterAccountId, quantity);
        _orderbook.triggerBalanceUpdated(waterAccountId, balances[identifier][waterAccountId]);
    }

    function allocateAll(
        bytes32[] memory identifiers,
        bytes32[] memory waterAccountIds,
        uint256[] memory quantities
    ) public {
        uint256 count = waterAccountIds.length;
        for (uint8 i = 0; i < count; i++) {
            balances[identifiers[i]][waterAccountIds[i]] = quantities[i];
        }
        _orderbook.triggerBalancesUpdated(waterAccountIds, quantities);
        _orderbook.triggerAllocationsComplete();
    }

    function debit(
        bytes32 identifier,
        bytes32 waterAccountId,
        uint256 quantity
    ) public onlyOrderBook {
        bool isValid = isFromTransferValid(identifier, quantity);

        require(level0Resources[identifier].level0ResourceExists, "This level0Resource is not valid");
        require(isValid, "Debit transfer not valid");
        require(balances[identifier][waterAccountId] >= quantity, "Balance not available");

        level0Resources[identifier].supply -= quantity;
        balances[identifier][waterAccountId] -= quantity;
        _orderbook.triggerBalanceUpdated(waterAccountId, balances[identifier][waterAccountId]);
    }

    function credit(
        bytes32 identifier,
        bytes32 waterAccountId,
        uint256 quantity
    ) public onlyOrderBook {
        bool isValid = isToTransferValid(identifier, quantity);

        require(level0Resources[identifier].level0ResourceExists, "This level0Resource is not valid");
        require(isValid, "Credit transfer not valid");

        level0Resources[identifier].supply += quantity;
        balances[identifier][waterAccountId] += quantity;
        _orderbook.triggerBalanceUpdated(waterAccountId, balances[identifier][waterAccountId]);
    }

    function restoreSupply(bytes32 identifier, uint256 quantity) public onlyOrderBook {
        level0Resources[identifier].supply += quantity;
    }

    function isToTransferValid(bytes32 identifier, uint256 value) public view returns (bool) {
        Level0Resource memory level0Resource = level0Resources[identifier];
        return (level0Resource.supply + value) <= level0Resource.max;
    }

    function isFromTransferValid(bytes32 identifier, uint256 value) public view returns (bool) {
        Level0Resource memory level0Resource = level0Resources[identifier];
        return (level0Resource.supply - value) >= level0Resource.min;
    }

    function getBalanceForLevel0Resource(bytes32 waterAccountId, bytes32 identifier) public view returns (uint256) {
        return balances[identifier][waterAccountId];
    }

    modifier onlyOrderBook() {
        if (msg.sender != owner()) {
            require(address(_orderbook) != address(0), "Orderbook must be set to make this transfer");
            require(address(_orderbook) == msg.sender, "Only the orderbook can make this transfer");
        }
        _;
    }
}
