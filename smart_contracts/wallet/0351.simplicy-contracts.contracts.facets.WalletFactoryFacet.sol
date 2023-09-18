// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import {WalletFactory} from "../wallet/factory/WalletFactory.sol";

contract WalletFactoryFacet is WalletFactory, OwnableInternal {
    /**
     * @notice return the current version of WalletFactoryFacets
     */
    function walletFactoryFacetVersion() public pure returns (string memory) {
        return "0.0.1";
    }

    function _beforeSetDiamond(address diamond)
        internal
        view
        virtual
        override
        onlyOwner
    {
        super._beforeSetDiamond(diamond);
    }

    function _beforeAddGuardian(bytes32 hashId, bytes32 guardian)
        internal
        view
        virtual
        override
        onlyOwner
    {
        super._beforeAddGuardian(hashId, guardian);
    }

    function _beforeRemoveGuardian(bytes32 hashId)
        internal
        view
        virtual
        override
        onlyOwner
    {
        super._beforeRemoveGuardian(hashId);
    }
}
