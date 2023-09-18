pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./IConstantsRepository.sol";
import "./Constants.sol";

// FIXME: Hardcoded addresses of the federation members, they should be changed once we settle with any
// The master key of all the addresses here is (they're all different transparent adresses of the same private wallet):
// m-test-shl-mk1fj335eanpmupaj9vx5879t7ljfnh7xct486rqgwxw8evwp2qkaks93ugg2 / m-main-shl-mk1fj335eanpmupaj9vx5879t7ljfnh7xct486rqgwxw8evwp2qkaks0gl9g4
contract MainnetConstantsRepository is IConstantsRepository {

    // Returns the size of the federation
    function federationSize() override external pure returns(uint) { return 3; }

    // Bech32 address is m-main-uns-ad1dqs4wqh450wq9dt8y5jc3pjflar669jm97a7cg with index 0
    // Private key is: 0fe5c80a3bde0d82f7d5858849aae19f05319e7eb1c728a4a35b26dfac400b0b
    address constant federationNodeAddress1 = 0x68215702F5A3DC02B5672525888649FF47Ad165b;

    // Bech32 address is m-main-uns-ad12ymht6jcua5v0r3e2aldneejyxc8frpmej2wwl with index 1
    // Private key is: 4ac365cf3d730892e66407c760b508517a8514034d6d6de4a383369d5a8ecd95
    address constant federationNodeAddress2 = 0x513775EA58E768c78E39577ed9E73221b0748c3B;

    // Bech32 address is m-main-uns-ad19fd4s46wh0e6dupzt40jjscre63ycnghye24pm with index 2
    // Private key is: 4bf433f00837b403413edb609b637771a8d1fee028773f32009692d84e37d121
    address constant federationNodeAddress3 = 0x2A5b58574EbBf3A6F0225D5f294303cea24C4d17;

    // It's not allowed to send money to the contract
    receive () external payable {
        assert(false);
    }

    /// Checks if the given address belongs to a federation node
    /// @param addr address to check
    function isValidFederationNodeKey(address addr) override external pure returns(bool) {
        return federationNodeAddress1 == addr || federationNodeAddress2 == addr || federationNodeAddress3 == addr;
    }

    /// Checks if the given chain is valid for the current network
    /// @param chainId chainId to check
    function isValidChainId(uint chainId) override external pure returns(bool) {
        // On main net only burns from other main nets are allowed
        return chainId == Constants.getBitcoinMainNetChainId() || chainId == Constants.getEthereumMainNetChainId();
    }

    uint constant minAge = 24;

    /// returns minimum age of commitment in number of blocks
    function getRevealMinAge() override external pure returns(uint) {
        return minAge;
    }

    // FIXME: Define this values for the mainnet
    function getEtcSnapshotStateRoot() override external pure returns(bytes32) { return bytes32(0); }
    function getTotalAtomToBeDistributed() override external pure returns(uint256) { return 0; }
    function getUnlockingStartBlock() override external pure returns(uint256) { return 0; }
    function getUnlockingEndBlock() override external pure returns(uint256) { return 0; }
    function getUnfreezingStartBlock() override external pure returns(uint256) { return 0; }
    function getEpochLength() override external pure returns(uint256) { return 0; }
    function getNumberOfEpochs() override external pure returns(uint256) { return 0; }
    function getPoWBaseTarget() override external pure returns(uint256) { return 0; }
    function getMinimumThreshold() override external pure returns(uint256) { return 0; }
}
