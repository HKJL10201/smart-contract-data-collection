// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

struct GeneralStorage {
    address factory;
    address moduleProvider;
}

library LibGeneral {
    bytes32 constant GENERAL_STORAGE = keccak256("1DeltaAccount.storage.general");

    function generalStorage() internal pure returns (GeneralStorage storage gs) {
        bytes32 position = GENERAL_STORAGE;
        assembly {
            gs.slot := position
        }
    }
}

abstract contract WithGeneralStorage {
    function gs() internal pure returns (GeneralStorage storage) {
        return LibGeneral.generalStorage();
    }
}
