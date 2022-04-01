pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "./TestnetConstantsRepository.sol";

// Makes all the hardcoded constants from GlacierDrop be configurable on deployment
contract ConfigurableConstantsRepository is TestnetConstantsRepository {

  bytes32 private etcSnapshotStateRoot;
  uint256 private totalAtomToBeDistributed;
  uint256 private unlockingStartBlock;
  uint256 private unlockingEndBlock;
  uint256 private unfreezingStartBlock;
  uint256 private epochLength;
  uint256 private numberOfEpochs;
  uint256 private powBaseTarget;
  uint256 private minimumThreshold;

  constructor(bytes32 etcSnapshotStateRootHash,
              uint256 totalAtomToBeDistributedGlacierDrop,
              uint256 unlockingStartBlockNumber,
              uint256 unlockingEndBlockNumber,
              uint256 unfreezingStartBlockNumber,
              uint256 epochBlockNumberLength,
              uint256 numberOfEpochsForUnfreezing,
              uint256 baseTarget,
              uint256 minimumETCThreshold
             ) payable {
    etcSnapshotStateRoot = etcSnapshotStateRootHash;
    totalAtomToBeDistributed = totalAtomToBeDistributedGlacierDrop;
    unlockingStartBlock = unlockingStartBlockNumber;
    unlockingEndBlock = unlockingEndBlockNumber;
    unfreezingStartBlock = unfreezingStartBlockNumber;
    epochLength = epochBlockNumberLength;
    numberOfEpochs = numberOfEpochsForUnfreezing;
    powBaseTarget = baseTarget;
    minimumThreshold = minimumETCThreshold;
  }

  function getEtcSnapshotStateRoot() override external view returns(bytes32) { return etcSnapshotStateRoot; }
  function getTotalAtomToBeDistributed() override external view returns(uint256) { return totalAtomToBeDistributed; }
  function getUnlockingStartBlock() override external view returns(uint256) { return unlockingStartBlock; }
  function getUnlockingEndBlock() override external view returns(uint256) { return unlockingEndBlock; }
  function getUnfreezingStartBlock() override external view returns(uint256) { return unfreezingStartBlock; }
  function getEpochLength() override external view returns(uint256) { return epochLength; }
  function getNumberOfEpochs() override external view returns(uint256) { return numberOfEpochs; }
  function getPoWBaseTarget() override external view returns(uint256) { return powBaseTarget; }
  function getMinimumThreshold() override external view returns(uint256) { return minimumThreshold; }
}
