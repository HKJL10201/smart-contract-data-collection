// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Zones is Ownable {
    struct Zone {
        bytes32 identifier;
        bool zoneExists;
        uint256 supply;
        uint256 min;
        uint256 max;
    }

    mapping(bytes32 => Zone) private zones;
    address private _orderbook;

    bytes32[] private zoneList;

    mapping(bytes32 => mapping(bytes32 => uint256)) private balances;

    constructor(address orderbook) Ownable() {
        _orderbook = orderbook;
    }

    function addZone(
        bytes32 identifier,
        uint256 supply,
        uint256 min,
        uint256 max
    ) public onlyOwner {
        zones[identifier] = Zone(identifier, true, supply, min, max);
        zoneList.push(identifier);
        emit ZoneAdded(identifier);
    }

    function getZoneList() public view returns (bytes32[] memory) {
        return zoneList;
    }

    function getZones() public view returns (Zone[] memory) {
        Zone[] memory zonesArray = new Zone[](zoneList.length);
        for(uint8 i = 0; i < zoneList.length; i++) {
            zonesArray[i] = zones[zoneList[i]];
        }
        return zonesArray;
    }

    function addAllZones(
        bytes32[] memory identifiers,
        uint256[] memory supplies,
        uint256[] memory mins,
        uint256[] memory maxes
    ) public onlyOwner {
        for (uint8 i = 0; i < identifiers.length; i++) {
            zones[identifiers[i]] = Zone(identifiers[i], true, supplies[i], mins[i], maxes[i]);
            zoneList.push(identifiers[i]);
        }
        emit ZonesAdded();
    }

    function allocate(
        bytes32 identifier,
        bytes32 waterAccountId,
        uint256 quantity
    ) public onlyOwner {
        require(zones[identifier].zoneExists, "This zone is not valid");
        balances[identifier][waterAccountId] = quantity;
        emit Allocation(identifier, waterAccountId, quantity);
        emit BalanceUpdated(waterAccountId, balances[identifier][waterAccountId]);
    }

    function allocateAll(bytes32[] memory identifiers, bytes32[] memory waterAccountIds,  uint256[] memory quantities) public {
        for (uint8 i = 0; i < waterAccountIds.length; i++) {
            balances[identifiers[i]][waterAccountIds[i]] = quantities[i];
        }
        emit BalancesUpdated(waterAccountIds, quantities);
        emit AllocationsComplete();
    }

    function debit(
        bytes32 identifier,
        bytes32 waterAccountId,
        uint256 quantity
    ) public onlyOrderBook {
        bool isValid = isFromTransferValid(identifier, quantity);

        require(zones[identifier].zoneExists, "This zone is not valid");
        require(isValid, "Debit transfer not valid");
        require(balances[identifier][waterAccountId] >= quantity, "Balance not available");

        zones[identifier].supply -= quantity;
        balances[identifier][waterAccountId] -= quantity;
        emit Debit(waterAccountId, identifier, quantity);
        emit BalanceUpdated(waterAccountId, balances[identifier][waterAccountId]);
    }

    function credit(
        bytes32 identifier,
        bytes32 waterAccountId,
        uint256 quantity
    ) public onlyOrderBook {
        bool isValid = isToTransferValid(identifier, quantity);

        require(zones[identifier].zoneExists, "This zone is not valid");
        require(isValid, "Credit transfer not valid");

        zones[identifier].supply += quantity;
        balances[identifier][waterAccountId] += quantity;
        emit Credit(waterAccountId, identifier, quantity);
        emit BalanceUpdated(waterAccountId, balances[identifier][waterAccountId]);
    }

    function restoreSupply(bytes32 identifier, uint256 quantity) public onlyOrderBook {
        zones[identifier].supply += quantity;
    }

    function isToTransferValid(bytes32 identifier, uint256 value) public view returns (bool) {
        Zone memory zone = zones[identifier];
        return (zone.supply + value) <= zone.max;
    }

    function isFromTransferValid(bytes32 identifier, uint256 value) public view returns (bool) {
        Zone memory zone = zones[identifier];
        return (zone.supply - value) >= zone.min;
    }

    function getBalanceForZone(bytes32 waterAccountId, bytes32 identifier) public view returns (uint256) {
        return balances[identifier][waterAccountId];
    }

    modifier onlyOrderBook() {
        if (msg.sender != owner()) {
            require(address(_orderbook) != address(0), "Orderbook must be set to make this transfer");
            require(_orderbook == msg.sender, "Only the orderbook can make this transfer");
        }
        _;
    }

    event Credit(bytes32 waterAccountId, bytes32 identifier, uint256 quantity);
    event Debit(bytes32 waterAccountId, bytes32 identifier, uint256 quantity);
    event BalanceUpdated(bytes32 waterAccountId, uint256 balance);
    event BalancesUpdated(bytes32[] waterAccountIds, uint256[] balances);
    event Allocation(bytes32 identifier, bytes32 waterAccountId, uint256 quantity);
    event AllocationsComplete();
    event ZoneAdded(bytes32 identifier);
    event ZonesAdded();
}
