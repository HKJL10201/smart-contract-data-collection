pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
interface IConstantsRepository {

    // Returns the size of the federation
    function federationSize() external view returns(uint);

    /// Checks if the given address belongs to a federation node
    /// @param addr address to check
    function isValidFederationNodeKey(address addr) external view returns(bool);

    /// Checks if the given chain is valid for the current network
    /// @param chainId chainId to check
    function isValidChainId(uint chainId) external view returns(bool);

    // FIXME [MID-787] define correct k when params of midnight consensus will be known
    /// returns minimum age of commitment in number of blocks
    function getRevealMinAge() external view returns(uint);

    function getEtcSnapshotStateRoot() external view returns(bytes32);

    // Total amount of atom to be assigned to the people that unlock their ether for the drop
    // The contract has to be assigned on creation with this amount of atom to work as expected
    function getTotalAtomToBeDistributed() external view returns(uint256);

    // Block number at which the unlocking period from glacier drop starts
    function getUnlockingStartBlock() external view returns(uint256);
    // Block number at which the unlocking period from glacier drop ends
    function getUnlockingEndBlock() external view returns(uint256);

    /**
        Epochs intervals (on block numbers) are:
         - Epoch 0 -> [UNFREEZING_START_BLOCK, UNFREEZING_START_BLOCK + EPOCH_LENGTH)
         - Epoch 1 -> [end epoch 0, end epoch 0 + EPOCH_LENGTH)
         ...
         - Epoch NUMBER_OF_EPOCHS-1 -> [end epoch NUMBER_OF_EPOCHS-2, infinity)
    */
    // Block number at which the unfreezing period from glacier drop ends
    function getUnfreezingStartBlock() external view returns(uint256);

    // Length of the epoch (remember that the last epoch is infinite)
    function getEpochLength() external view returns(uint256);

    // Number of epochs on the unfreezing period
    // Note: This number has be an odd one
    function getNumberOfEpochs() external view returns(uint256);

    // Base target used to calculate target for Glacier Drop PoW (baseTarget / difficulty)
    function getPoWBaseTarget() external view returns(uint256);

    // Minimum balance that ETC owners need to have for participating in the glacier drop
    function getMinimumThreshold() external view returns(uint256);
}