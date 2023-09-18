// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

// We do not use an array of stucts to avoid pointer conflicts

struct GeneralStorage {
    address factory;
    bool initialized;
}

struct UserAccountStorage {
    address previousAccountOwner;
    address accountOwner;
    mapping(address => bool) managers;
    string accountName;
    uint256 creationTimestamp;
}

struct DataProviderStorage {
    address dataProvider;
}

// for exact output multihop swaps
struct NumberCache {
    uint256 amount;
}

// for exact output multihop swaps
struct AddressCache {
    address cachedAddress;
}

library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the project
    bytes32 constant DATA_PROVIDER_STORAGE = keccak256("1deltaAccount.storage.dataProvider");
    bytes32 constant GENERAL_STORAGE = keccak256("1deltaAccount.storage.general");
    bytes32 constant USER_ACCOUNT_STORAGE = keccak256("1deltaAccount.storage.user");
    bytes32 constant UNISWAP_STORAGE = keccak256("1deltaAccount.storage.uniswap");
    bytes32 constant NUMBER_CACHE = keccak256("1deltaAccount.storage.cache.number");
    bytes32 constant ADDRESS_CACHE = keccak256("1deltaAccount.storage.cache.address");

    function dataProviderStorage() internal pure returns (DataProviderStorage storage ps) {
        bytes32 position = DATA_PROVIDER_STORAGE;
        assembly {
            ps.slot := position
        }
    }

    function generalStorage() internal pure returns (GeneralStorage storage gs) {
        bytes32 position = GENERAL_STORAGE;
        assembly {
            gs.slot := position
        }
    }

    function userAccountStorage() internal pure returns (UserAccountStorage storage us) {
        bytes32 position = USER_ACCOUNT_STORAGE;
        assembly {
            us.slot := position
        }
    }

    function enforceManager() internal view {
        require(userAccountStorage().managers[msg.sender], "Only manager can interact.");
    }

    function enforceAccountOwner() internal view {
        require(msg.sender == userAccountStorage().accountOwner, "Only the account owner can interact.");
    }

    function numberCacheStorage() internal pure returns (NumberCache storage ncs) {
        bytes32 position = NUMBER_CACHE;
        assembly {
            ncs.slot := position
        }
    }

    function addressCacheStorage() internal pure returns (AddressCache storage cs) {
        bytes32 position = ADDRESS_CACHE;
        assembly {
            cs.slot := position
        }
    }
}

/**
 * The `WithStorage` contract provides a base contract for Module contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.treasuryStorage()` to just `ts()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
abstract contract WithStorage {
    function ps() internal pure returns (DataProviderStorage storage) {
        return LibStorage.dataProviderStorage();
    }

    function gs() internal pure returns (GeneralStorage storage) {
        return LibStorage.generalStorage();
    }

    function us() internal pure returns (UserAccountStorage storage) {
        return LibStorage.userAccountStorage();
    }

    function ncs() internal pure returns (NumberCache storage) {
        return LibStorage.numberCacheStorage();
    }

    function acs() internal pure returns (AddressCache storage) {
        return LibStorage.addressCacheStorage();
    }
}
