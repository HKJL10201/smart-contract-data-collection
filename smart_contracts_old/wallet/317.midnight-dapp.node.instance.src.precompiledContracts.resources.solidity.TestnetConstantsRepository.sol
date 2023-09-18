pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./IConstantsRepository.sol";
import "./Constants.sol";

// Chrysalis testnet constants contract.
// There are 5 valid federation address: 3 of them belongs to vacuum labs, 2 of them belongs to midnight qa team
// Federation size is set to 3, to make it possible for either vacuum or qa federation nodes to achieve majority
contract TestnetConstantsRepository is IConstantsRepository {

    // Returns the size of the federation
    // Majority was changed to require 3 out of the 6 federation members for reaching consensus
    function federationSize() override external pure returns(uint) { return 5; }

    // Federation member controlled by VacuumLabs
    // Bech32 address is m-test-uns-ad1qy337rvxt4faer7cw8q83a9gvq0fv382sd30yq
    address constant federationNodeAddress1 = 0x01231f0D865D53dC8fD871c078F4a8601E9644ea;

    // Federation member controlled by VacuumLabs
    // Bech32 address is m-test-uns-ad1z6wrjaufl054amy9g393dtunjewt2exsl0qun8
    address constant federationNodeAddress2 = 0x169c397789fbE95Eec85444b16AF93965CB564D0;

    // Federation member controlled by VacuumLabs
    // Bech32 address is m-test-uns-ad19rw3zap4602zd4535qxcfnt2p895mltf67sg6r
    address constant federationNodeAddress3 = 0x28DD117435D3d426D691a00d84CD6a09Cb4dfd69;

    // Federation member controlled by IOHK
    // Bech32 address is m-test-uns-ad1ymu4z3csagkn5r6p2fcnqdxfapcx9tsqkdhw7t
    address constant federationNodeAddress4 = 0x26f9514710EA2D3a0f4152713034c9E87062aE00;

    // Federation member controlled by IOHK
    // Bech32 address is m-test-uns-ad1u9f678pws9qlcrvv4atj4sayrkhpwecdj04p55
    address constant federationNodeAddress5 = 0xe153af1c2E8141Fc0d8CAF572AC3a41DAE17670d;

    // Federation member controlled by IOHK
    // Bech32 address is m-test-uns-ad12yynnye4rwqydqn0rfhdqru93al62wqvw6rg6v
    address constant federationNodeAddress6 = 0x51093993351b8046826F1A6Ed00F858f7fa5380c;

    // It's not allowed to send money to the contract
    receive () external payable {
        assert(false);
    }

    /// Checks if the given address belongs to a federation node
    /// @param addr address to check
    function isValidFederationNodeKey(address addr) override external pure returns(bool) {
        return federationNodeAddress1 == addr ||
        federationNodeAddress2 == addr ||
        federationNodeAddress3 == addr ||
        federationNodeAddress4 == addr ||
        federationNodeAddress5 == addr ||
        federationNodeAddress6 == addr;
    }

    /// Checks if the given chain is valid for the current network
    /// @param chainId chainId to check
    function isValidChainId(uint chainId) override external pure returns(bool) {
        // On test net only burns from other test nets are allowed
        return chainId == Constants.getBitcoinTestNetChainId() || chainId == Constants.getEthereumTestNetChainId();
    }

    uint constant minAge = 10;

    /// returns minimum age of commitment in number of blocks
    function getRevealMinAge() override external pure returns(uint) {
        return minAge;
    }

    // State root hash of the block 2M010K from kotti testnet
    function getEtcSnapshotStateRoot() virtual override external view returns(bytes32) { return 0x1201ec2c167354da473c6c3230c20c4120dc0b8e977a9ee18f2338f9994cbceb; }

    // Total amount of atom to be distributed, has to be equal to the amount of available contract's funds
    function getTotalAtomToBeDistributed() virtual override external view returns(uint256) { return 100000000000; }

    // Given the current ratio of blocks produced on the testnet this gives a week or so since restart to unlock the funds
    function getUnlockingStartBlock() virtual override external view returns(uint256) { return 0; }
    function getUnlockingEndBlock() virtual override external view returns(uint256) { return 4999; }
    function getUnfreezingStartBlock() virtual override external view returns(uint256) { return 5000; }

    // Epochs configured so that a total amount of 5000 blocks (another week) is required for full unfreezing
    function getEpochLength() virtual override external view returns(uint256) { return 500; }
    function getNumberOfEpochs() virtual override external view returns(uint256) { return 10; }

    function getPoWBaseTarget() virtual override external view returns(uint256) { return 220645879637483770412702648900769088893722566804514143908781246501748575; }

    // Minimum threshold: 1 ether classic
    function getMinimumThreshold() virtual override external view returns(uint256) { return 1 ether; }
}