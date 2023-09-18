pragma solidity 0.6.7;

import "geb-treasury-reimbursement/reimbursement/single/IncreasingTreasuryReimbursement.sol";

abstract contract LiquidationEngineLike {
    function currentOnAuctionSystemCoins() virtual public view returns (uint256);
    function modifyParameters(bytes32, uint256) virtual external;
}
abstract contract SAFEEngineLike {
    function globalDebt() virtual public view returns (uint256);
    function globalUnbackedDebt() virtual public view returns (uint256);
    function coinBalance(address) virtual public view returns (uint256);
}

contract CollateralAuctionThrottler is IncreasingTreasuryReimbursement {
    // --- Variables ---
    // Minimum delay between consecutive updates
    uint256 public updateDelay;                     // [seconds]
    // Delay since the last update time after which backupLimitRecompute can be called
    uint256 public backupUpdateDelay;               // [seconds]
    // Percentage of global debt taken into account in order to set LiquidationEngine.onAuctionSystemCoinLimit
    uint256 public globalDebtPercentage;            // [hundred]
    // The minimum auction limit
    uint256 public minAuctionLimit;                 // [rad]
    // Last timestamp when the onAuctionSystemCoinLimit was updated
    uint256 public lastUpdateTime;                  // [unix timestamp]

    LiquidationEngineLike    public liquidationEngine;
    SAFEEngineLike           public safeEngine;

    // List of surplus holders
    address[]                public surplusHolders;

    constructor(
      address safeEngine_,
      address liquidationEngine_,
      address treasury_,
      uint256 updateDelay_,
      uint256 backupUpdateDelay_,
      uint256 baseUpdateCallerReward_,
      uint256 maxUpdateCallerReward_,
      uint256 perSecondCallerRewardIncrease_,
      uint256 globalDebtPercentage_,
      address[] memory surplusHolders_
    ) public IncreasingTreasuryReimbursement(treasury_, baseUpdateCallerReward_, maxUpdateCallerReward_, perSecondCallerRewardIncrease_) {
        require(safeEngine_ != address(0), "CollateralAuctionThrottler/null-safe-engine");
        require(liquidationEngine_ != address(0), "CollateralAuctionThrottler/null-liquidation-engine");
        require(updateDelay_ > 0, "CollateralAuctionThrottler/null-update-delay");
        require(backupUpdateDelay_ > updateDelay_, "CollateralAuctionThrottler/invalid-backup-update-delay");
        require(both(globalDebtPercentage_ > 0, globalDebtPercentage_ <= HUNDRED), "CollateralAuctionThrottler/invalid-global-debt-percentage");
        require(surplusHolders_.length <= HOLDERS_ARRAY_LIMIT, "CollateralAuctionThrottler/invalid-holder-array-length");

        safeEngine             = SAFEEngineLike(safeEngine_);
        liquidationEngine      = LiquidationEngineLike(liquidationEngine_);
        updateDelay            = updateDelay_;
        backupUpdateDelay      = backupUpdateDelay_;
        globalDebtPercentage   = globalDebtPercentage_;
        surplusHolders         = surplusHolders_;

        emit ModifyParameters(bytes32("updateDelay"), updateDelay);
        emit ModifyParameters(bytes32("globalDebtPercentage"), globalDebtPercentage);
        emit ModifyParameters(bytes32("backupUpdateDelay"), backupUpdateDelay);
    }

    // --- Math ---
    uint256 internal constant ONE                 = 1;
    uint256 internal constant HOLDERS_ARRAY_LIMIT = 10;
    uint256 internal constant HUNDRED             = 100;

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notify Modify a uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param data The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "baseUpdateCallerReward") {
          require(data <= maxUpdateCallerReward, "CollateralAuctionThrottler/invalid-min-reward");
          baseUpdateCallerReward = data;
        }
        else if (parameter == "maxUpdateCallerReward") {
          require(data >= baseUpdateCallerReward, "CollateralAuctionThrottler/invalid-max-reward");
          maxUpdateCallerReward = data;
        }
        else if (parameter == "perSecondCallerRewardIncrease") {
          require(data >= RAY, "CollateralAuctionThrottler/invalid-reward-increase");
          perSecondCallerRewardIncrease = data;
        }
        else if (parameter == "maxRewardIncreaseDelay") {
          require(data > 0, "CollateralAuctionThrottler/invalid-max-increase-delay");
          maxRewardIncreaseDelay = data;
        }
        else if (parameter == "updateDelay") {
          require(data > 0, "CollateralAuctionThrottler/null-update-delay");
          updateDelay = data;
        }
        else if (parameter == "backupUpdateDelay") {
          require(data > updateDelay, "CollateralAuctionThrottler/invalid-backup-update-delay");
          backupUpdateDelay = data;
        }
        else if (parameter == "globalDebtPercentage") {
          require(both(data > 0, data <= HUNDRED), "CollateralAuctionThrottler/invalid-global-debt-percentage");
          globalDebtPercentage = data;
        }
        else if (parameter == "minAuctionLimit") {
          minAuctionLimit = data;
        }
        else revert("CollateralAuctionThrottler/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify the address of a contract param
    * @param parameter The name of the parameter to change the address for
    * @param addr The new address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "CollateralAuctionThrottler/null-addr");
        if (parameter == "treasury") {
          require(StabilityFeeTreasuryLike(addr).systemCoin() != address(0), "CollateralAuctionThrottler/treasury-coin-not-set");
      	  treasury = StabilityFeeTreasuryLike(addr);
        }
        else if (parameter == "liquidationEngine") {
          liquidationEngine = LiquidationEngineLike(addr);
        }
        else revert("CollateralAuctionThrottler/modify-unrecognized-param");
        emit ModifyParameters(parameter, addr);
    }

    // --- Recompute Logic ---
    /*
    * @notify Recompute and set the new onAuctionSystemCoinLimit
    * @param feeReceiver The address that will receive the reward for recomputing the onAuctionSystemCoinLimit
    */
    function recomputeOnAuctionSystemCoinLimit(address feeReceiver) public {
        // Check delay between calls
        require(either(subtract(now, lastUpdateTime) >= updateDelay, lastUpdateTime == 0), "CollateralAuctionThrottler/wait-more");
        // Get the caller's reward
        uint256 callerReward = getCallerReward(lastUpdateTime, updateDelay);
        // Store the timestamp of the update
        lastUpdateTime = now;
        // Compute total surplus
        uint256 totalSurplus;
        for (uint i = 0; i < surplusHolders.length; i++) {
          totalSurplus = addition(totalSurplus, safeEngine.coinBalance(surplusHolders[i]));
        }
        // Remove surplus from global debt
        uint256 rawGlobalDebt               = subtract(safeEngine.globalDebt(), totalSurplus);
        rawGlobalDebt                       = subtract(rawGlobalDebt, safeEngine.globalUnbackedDebt());
        // Calculate and set the onAuctionSystemCoinLimit
        uint256 newAuctionLimit             = multiply(rawGlobalDebt / HUNDRED, globalDebtPercentage);
        uint256 currentOnAuctionSystemCoins = liquidationEngine.currentOnAuctionSystemCoins();
        newAuctionLimit                     = (newAuctionLimit <= minAuctionLimit) ? minAuctionLimit : newAuctionLimit;
        newAuctionLimit                     = (newAuctionLimit == 0) ? uint(-1) : newAuctionLimit;
        newAuctionLimit                     = (newAuctionLimit < currentOnAuctionSystemCoins) ? currentOnAuctionSystemCoins : newAuctionLimit;
        liquidationEngine.modifyParameters("onAuctionSystemCoinLimit", newAuctionLimit);
        // Pay the caller for updating the rate
        rewardCaller(feeReceiver, callerReward);
    }
    /*
    * @notify Backup function for recomputing the onAuctionSystemCoinLimit in case of a severe delay since the last update
    */
    function backupRecomputeOnAuctionSystemCoinLimit() public {
        // Check delay between calls
        require(both(subtract(now, lastUpdateTime) >= backupUpdateDelay, lastUpdateTime > 0), "CollateralAuctionThrottler/wait-more");
        // Store the timestamp of the update
        lastUpdateTime = now;
        // Set the onAuctionSystemCoinLimit
        liquidationEngine.modifyParameters("onAuctionSystemCoinLimit", uint(-1));
    }
}
