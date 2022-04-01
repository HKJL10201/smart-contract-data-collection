pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "../Constants.sol";
import "../utils/CallPrecompiledContract.sol";
import "../utils/SafeMath.sol";
import "../IConstantsRepository.sol";
import "./AuthorizationMessageVerifier.sol";
import "./PoWValidator.sol";
import "./EpochsForUnfreezeCalculator.sol";
import "./EtcToDustConverter.sol";

contract GlacierDrop is PoWValidator, EpochsForUnfreezeCalculator, AuthorizationMessageVerifier, EtcToDustConverter {
  using SafeMath for uint256;

  // Whether each etc owner has unlocked their funds for the glacier drop or not
  mapping(address => bool) private etcOwnersFundsUnlocked;

  // ETC balances statistics
  struct ETCBalancesStatistics {
    uint256 totalUnlockedEther;
    uint256 totalNumberAccounts;
    uint256 minimumUnlockedEther;
    uint256 maximumUnlockedEther;
  }
  ETCBalancesStatistics private etcBalancesStatistics;

  struct PendingDrop {
    address midnightDropSender;
    address midnightDropReceiver;
    uint256 totalEther;
    uint256 totalDust;
    uint256 withdrawnDust;
  }

  // Drops to be redeemed (identified by the ETC owner as each performs a single drop)
  mapping(address => PendingDrop) private dropsToBeWithdrawn;

  event Unlocked (
    address etcOwner,
    uint256 etcBalance,
    address midnightDropSender,
    address midnightDropReceiver
  );

  event Withdrawn (
    address etcOwner,
    address midnightDropSender,
    address midnightDropReceiver,
    uint256 currentEpoch,
    uint256 dustWithdrawn,
    uint256 totalDustUnlocked
  );

  function getTotalUnlockedEther() view public returns(uint256) {
    return etcBalancesStatistics.totalUnlockedEther;
  }

  function getDustWithdrawnByUser(address etcOwner) view public returns(uint256) {
    IConstantsRepository constantsRepository = IConstantsRepository(getConstantsRepositoryAddress());
    checkIfUnfreezingStarted(constantsRepository.getUnfreezingStartBlock());
    PendingDrop storage dropToWithdraw = dropsToBeWithdrawn[etcOwner];
    return dropToWithdraw.withdrawnDust;
  }

  function getNumberOfEpochsForFullUnfreeze(address etcOwner) view public returns(uint256) {
    IConstantsRepository constantsRepository = IConstantsRepository(getConstantsRepositoryAddress());
    checkIfUnfreezingStarted(constantsRepository.getUnfreezingStartBlock());
    PendingDrop storage dropToWithdraw = dropsToBeWithdrawn[etcOwner];
    uint256 unlockedEther = dropToWithdraw.totalEther;
    checkIfDropUnlocked(unlockedEther);
    uint256 averageUnlockedEther = calculateAverageUnlockedEther();
    return numberEpochsForFullUnfreeze(
      unlockedEther,
      etcBalancesStatistics.minimumUnlockedEther,
      averageUnlockedEther,
      etcBalancesStatistics.maximumUnlockedEther,
      constantsRepository.getNumberOfEpochs()
    );
  }


  /// First step for the glacier drop flow, the user unlocks their ether for the glacier drop with all the proofs required
  /// @param dustReceiverString midnight transparent address that will be receiving the dust from the drop, in bech32 format
  /// @param etcOwnerString ETC address that owned the ether, in hex format (prefixed by 0x)
  /// @param signatureV v part of the ETC authorization signature
  /// @param signatureR r part of the ETC authorization signature
  /// @param signatureS s part of the ETC authorization signature
  /// @param inclusionProof proof that the ETC owner had balance at the time of the snapshot
  /// @param powNonce proof of the PoW put into this drop
  function unlock(string memory dustReceiverString,
                  string memory etcOwnerString,
                  uint8 signatureV,
                  bytes32 signatureR,
                  bytes32 signatureS,
                  bytes memory inclusionProof,
                  uint64 powNonce
                 ) public {
    IConstantsRepository constantsRepository = IConstantsRepository(getConstantsRepositoryAddress());

    // Verify that the tx is inside the unlock period
    require(constantsRepository.getUnlockingStartBlock() <= block.number, "Unlocking period has not yet started");
    require(block.number <= constantsRepository.getUnlockingEndBlock(), "Unlocking period has already ended");

    // Verify the signature of the etc owner
    (address dustReceiver, address etcOwner) = verifyAuthorizationMessage(dustReceiverString, etcOwnerString, signatureV, signatureR, signatureS);

    /// Verify registration was not done before
    require(!etcOwnersFundsUnlocked[etcOwner], "ETC owner already unlocked his funds");
    etcOwnersFundsUnlocked[etcOwner] = true;

    // Verify that the account had balance on the ETC snapshot and obtain it
    uint256 etcBalance = verifyInclusionAndGetBalance(constantsRepository.getEtcSnapshotStateRoot(), etcOwner, inclusionProof);
    require(etcBalance != uint256(0), "ETC owner has no funds or the submitted proof is invalid");

    // Verify that the account's balance is over the minimum threshold
    require(etcBalance >= constantsRepository.getMinimumThreshold(), "ETC owner balance is less than the minimum");

    // Validate PoW
    uint256 powBaseTarget = constantsRepository.getPoWBaseTarget();
    bool isValid = validatePoW(
        etcOwner,
        etcBalance,
        powNonce,
        powBaseTarget,
        constantsRepository.getUnlockingStartBlock(),
        constantsRepository.getUnlockingEndBlock()
    );
    require(isValid, "Passed nonce is not valid proof of work");

    // Enable funds to be withdrawn
    dropsToBeWithdrawn[etcOwner] = PendingDrop(msg.sender, dustReceiver, etcBalance, 0, 0);

    // Update the total ether unlocked
    updateETCBalancesStatistics(etcBalance);

    emit Unlocked(etcOwner, etcBalance, msg.sender, dustReceiver);
  }

  /// Second step of the glacier flow, the user withdraws the funds from the drop, having them identified by the ETC owner
  /// @param etcOwner ETC address with which the sender of this tx has unlocked his funds
  function withdraw(address etcOwner) public {
    IConstantsRepository constantsRepository = IConstantsRepository(getConstantsRepositoryAddress());

    // Verify that the tx is inside the unfreezing period
    uint256 unfreezingStartBlock = constantsRepository.getUnfreezingStartBlock();
    checkIfUnfreezingStarted(unfreezingStartBlock);

    // Verify that the sender has unlocked his funds
    PendingDrop memory dropToWithdraw = dropsToBeWithdrawn[etcOwner];
    uint256 totalAtomToBeDistributed = constantsRepository.getTotalAtomToBeDistributed();
    uint256 totalDust;

    checkIfDropUnlocked(dropToWithdraw.totalEther);
    if(dropToWithdraw.totalDust == 0) {
        // Convert the ether to be withdrawn to dust
        totalDust = convertEtherClassicToDust(dropToWithdraw.totalEther, etcBalancesStatistics.totalUnlockedEther, totalAtomToBeDistributed);
        dropsToBeWithdrawn[etcOwner].totalDust = totalDust;
    } else {
        totalDust = dropsToBeWithdrawn[etcOwner].totalDust;
    }
    require(totalDust > dropToWithdraw.withdrawnDust, "The user has withdrawn all its available dust");
    require(msg.sender == dropToWithdraw.midnightDropSender, "Only the one that unlocked the drop can perform the withdraw");

    // Calculate the amount of dust unfreeze at the current epoch
    uint256 numberOfEpochs = constantsRepository.getNumberOfEpochs();
    uint256 currentEpoch = getCurrentRedeemEpochIndex(unfreezingStartBlock, constantsRepository.getEpochLength(), numberOfEpochs);
    uint256 dustToWithdraw = dustUnfrozenAtEpoch(dropToWithdraw.totalEther, totalDust, currentEpoch, numberOfEpochs) - dropToWithdraw.withdrawnDust;
    require(dustToWithdraw > 0, "There's no unredeemed dust unfrozen");

    // Register that the withdraw was already done
    dropsToBeWithdrawn[etcOwner].withdrawnDust += dustToWithdraw;

    // Perform the withdraw (call is used for the case that the withdrawer of the dust is a smart contract)
    (bool transferSuccessful, ) = dropToWithdraw.midnightDropReceiver.call{value: dustToWithdraw}("");
    require(transferSuccessful, "Transfer of withdrawn failed");
    emit Withdrawn(
        etcOwner,
        msg.sender,
        dropToWithdraw.midnightDropReceiver,
        currentEpoch,
        dustToWithdraw,
        totalDust
     );
  }

  function checkIfUnfreezingStarted(uint256 unfreezingStartBlock) view internal {
     require(unfreezingStartBlock <= block.number, "Unfreezing period has not yet started");
  }

  function checkIfDropUnlocked(uint256 totalEther) pure internal {
     require(totalEther > 0, "There's no unlocked drop for this ETC address");
  }

  function verifyInclusionAndGetBalance(bytes32 stateTrieRoot,
                                        address etcAddress,
                                        bytes memory inclusionProof) internal returns (uint256 etcBalance) {
    bytes memory encodedInputData = abi.encode(
                                              stateTrieRoot,
                                              etcAddress,
                                              inclusionProof);
    address verifierAddr = Constants.glacierDropVerifier();
    bytes32 etcBalanceBytes = CallPrecompiledContract.callPrecompiledContract(verifierAddr, encodedInputData, "ETC owner has no funds or the submitted proof is invalid");
    return uint256(etcBalanceBytes);
  }

  function updateETCBalancesStatistics(uint256 etcOwnerBalance) internal {
    etcBalancesStatistics.totalUnlockedEther += etcOwnerBalance;

    etcBalancesStatistics.totalNumberAccounts += 1;

    if (etcBalancesStatistics.minimumUnlockedEther == 0 || etcOwnerBalance < etcBalancesStatistics.minimumUnlockedEther) {
        etcBalancesStatistics.minimumUnlockedEther = etcOwnerBalance;
    }

    if (etcOwnerBalance > etcBalancesStatistics.maximumUnlockedEther) {
        etcBalancesStatistics.maximumUnlockedEther = etcOwnerBalance;
    }
   }

  // This is only called on txs after the withdraw period has started
  function getCurrentRedeemEpochIndex(uint256 unfreezingStartBlock, uint256 epochLength, uint256 numberOfEpochs) view internal returns (uint256) {
    uint256 epochNumberNotSaturated = (block.number - unfreezingStartBlock) / epochLength;
    if(epochNumberNotSaturated >= numberOfEpochs) {
        return numberOfEpochs - 1;
    } else {
        return epochNumberNotSaturated;
    }
  }

  function dustUnfrozenAtEpoch(uint256 totalUserEtherUnlocked, uint256 totalUserDustUnlocked, uint256 epochIndex, uint256 numberOfEpochs) view internal returns (uint256) {
    uint256 averageUnlockedEther = calculateAverageUnlockedEther();
    uint256 numberOfEpochsForFullUnfreeze = numberEpochsForFullUnfreeze(
        totalUserEtherUnlocked,
        etcBalancesStatistics.minimumUnlockedEther,
        averageUnlockedEther,
        etcBalancesStatistics.maximumUnlockedEther,
        numberOfEpochs
    );

    // dustUnlockedPerEpoch * numberOfEpochs could be less than totalUserDustUnlocked, so we treat the epochs since full unfreeze
    // separately to withdraw in it any minor dust left
    if(epochIndex >= numberOfEpochsForFullUnfreeze - 1) {
        return totalUserDustUnlocked;
    } else {
        uint256 dustUnlockedPerEpoch = totalUserDustUnlocked / numberOfEpochsForFullUnfreeze;
        return dustUnlockedPerEpoch * (epochIndex + 1);
    }
  }

  function calculateAverageUnlockedEther() view internal returns (uint256) {
    return etcBalancesStatistics.totalUnlockedEther / etcBalancesStatistics.totalNumberAccounts;
  }

  // Interface that allows overriding this value on contracts that inherit from this one
  function getConstantsRepositoryAddress() virtual internal view returns(address){
    return Constants.constantsRepository();
  }
}
