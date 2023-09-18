pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./DevelopmentConstantsRepository.sol";

// Overrides constants from development for easier testing
contract MockConstantsRepository is DevelopmentConstantsRepository {

    // Returns the size of the federation
    function federationSize() override external view returns(uint) { return federationNodes.length; }

    address[] federationNodes;
    bytes32 etcSnapshotStateRoot;
    uint256 totalAtomToBeDistributed;
    uint256 powBaseTarget;

    constructor(address[] memory federationNodeAddresses, bytes32 etcSnapshotStateRootHash, uint256 totalAtomToBeDistributedGlacierDrop, uint256 baseTarget) {
        federationNodes = federationNodeAddresses;
        etcSnapshotStateRoot = etcSnapshotStateRootHash;
        totalAtomToBeDistributed = totalAtomToBeDistributedGlacierDrop;
        powBaseTarget = baseTarget;
    }

    /// Checks if the given address belongs to a federation node
    /// @param addr address to check
    function isValidFederationNodeKey(address addr) override external view returns(bool) {
        for(uint i = 0; i < federationNodes.length; i++){
            if (addr == federationNodes[i]) {
                return true;
            }
        }
        return false;
    }

    /// Checks if the given chain is valid for the current network
    /// @param chainId chainId to check
    function isValidChainId(uint chainId) override external pure returns(bool) {
        return chainId <= 3;
    }

    function getEtcSnapshotStateRoot() override external view returns(bytes32) { return etcSnapshotStateRoot; }
    function getTotalAtomToBeDistributed() override external view returns(uint256) { return totalAtomToBeDistributed; }
    function getPoWBaseTarget() override external view returns(uint256) { return powBaseTarget; }
}