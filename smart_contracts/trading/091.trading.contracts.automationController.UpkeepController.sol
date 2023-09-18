// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {UpkeepInfo, State, OnchainConfig, UpkeepFailureReason} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {EnumerableSet} from "@openzeppelin/contractsV4/access/AccessControlEnumerable.sol";
import {AutomationCompatibleWithViewInterface} from "./interfaces/AutomationCompatibleWithViewInterface.sol";
import {AutomationRegistryWithMinANeededAmountInterface} from "./interfaces/AutomationRegistryWithMinANeededAmountInterface.sol";
import {KeeperRegistrarInterface} from "./interfaces/KeeperRegistrarInterface.sol";
import {UpkeepControllerInterface} from "./interfaces/UpkeepControllerInterface.sol";

/**
 * @title UpkeepController contract
 * @notice A contract that manages upkeeps for the Chainlink automation system.
 * @dev This contract implements the UpkeepControllerInterface and provides functionality to register, cancel,
 * pause, and unpause upkeeps, as well as update their check data, gas limits, and off-chain configurations.
 */
contract UpkeepController is UpkeepControllerInterface {
    using EnumerableSet for EnumerableSet.UintSet;

    LinkTokenInterface public immutable i_link;
    KeeperRegistrarInterface public immutable i_registrar;
    AutomationRegistryWithMinANeededAmountInterface public immutable i_registry;

    EnumerableSet.UintSet private activeUpkeeps;
    EnumerableSet.UintSet private pausedUpkeeps;

    /**
     * @notice Constructs the UpkeepController contract.
     * @param link The address of the LinkToken contract.
     * @param registrar The address of the KeeperRegistrar contract.
     * @param registry The address of the AutomationRegistry contract.
     */
    constructor(
        LinkTokenInterface link,
        KeeperRegistrarInterface registrar,
        AutomationRegistryWithMinANeededAmountInterface registry
    ) {
        i_link = link;
        i_registrar = registrar;
        i_registry = registry;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function registerAndPredictID(KeeperRegistrarInterface.RegistrationParams memory params) public {
        i_link.transferFrom(msg.sender, address(this), params.amount);
        i_link.approve(address(i_registrar), params.amount);
        uint256 upkeepId = i_registrar.registerUpkeep(params);
        if (upkeepId != 0) {
            activeUpkeeps.add(upkeepId);
            emit UpkeepCreated(upkeepId);
        } else {
            revert("auto-approve disabled");
        }
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function cancelUpkeep(uint256 upkeepId) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.cancelUpkeep(upkeepId);
        activeUpkeeps.remove(upkeepId);
        emit UpkeepCanceled(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function pauseUpkeep(uint256 upkeepId) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.pauseUpkeep(upkeepId);
        pausedUpkeeps.add(upkeepId);
        activeUpkeeps.remove(upkeepId);
        emit UpkeepPaused(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function unpauseUpkeep(uint256 upkeepId) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.unpauseUpkeep(upkeepId);
        pausedUpkeeps.remove(upkeepId);
        activeUpkeeps.add(upkeepId);
        emit UpkeepUnpaused(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function updateCheckData(uint256 upkeepId, bytes memory newCheckData) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.updateCheckData(upkeepId, newCheckData);
        emit UpkeepUpdated(upkeepId, newCheckData);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function setUpkeepGasLimit(uint256 upkeepId, uint32 gasLimit) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.setUpkeepGasLimit(upkeepId, gasLimit);
        emit UpkeepGasLimitSet(upkeepId, gasLimit);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function setUpkeepOffchainConfig(uint256 upkeepId, bytes calldata config) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.setUpkeepOffchainConfig(upkeepId, config);
        emit UpkeepOffchainConfigSet(upkeepId, config);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function addFunds(uint256 upkeepId, uint96 amount) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_link.transferFrom(msg.sender, address(this), amount);
        i_link.approve(address(i_registry), amount);
        i_registry.addFunds(upkeepId, amount);
        emit FundsAdded(upkeepId, amount);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getUpkeep(uint256 upkeepId) external view returns (UpkeepInfo memory upkeepInfo) {
        return i_registry.getUpkeep(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getActiveUpkeepIDs(uint256 offset, uint256 limit) public view returns (uint256[] memory upkeeps) {
        uint256 ordersCount = activeUpkeeps.length();
        if (offset >= ordersCount) return new uint256[](0);
        uint256 to = offset + limit;
        if (ordersCount < to) to = ordersCount;
        upkeeps = new uint256[](to - offset);
        for (uint256 i = 0; i < upkeeps.length; i++) upkeeps[i] = activeUpkeeps.at(offset + i);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getUpkeeps(uint256 offset, uint256 limit) public view returns (UpkeepInfo[] memory) {
        uint256[] memory activeIds = getActiveUpkeepIDs(offset, limit); // FIX IT
        UpkeepInfo[] memory upkeepsInfo = new UpkeepInfo[](activeIds.length);
        for (uint256 i = 0; i < upkeepsInfo.length; i++) {
            upkeepsInfo[i] = i_registry.getUpkeep(activeIds[i]);
        }
        return upkeepsInfo;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getMinBalanceForUpkeep(uint256 upkeepId) external view returns (uint96) {
        return i_registry.getMinBalanceForUpkeep(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getMinBalancesForUpkeeps(uint256 offset, uint256 limit) public view returns (uint96[] memory) {
        uint256[] memory activeIds = getActiveUpkeepIDs(offset, limit);
        uint256 count = activeIds.length;
        if (offset >= count) return new uint96[](0);
        uint256 to = offset + limit;
        if (count < to) to = count;
        uint96[] memory upkeepsMinAmounts = new uint96[](to - offset);
        for (uint256 i = 0; i < upkeepsMinAmounts.length; i++) {
            upkeepsMinAmounts[i] = i_registry.getMinBalanceForUpkeep(activeIds[i]);
        }
        return upkeepsMinAmounts;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getDetailedUpkeeps(uint256 offset, uint256 limit) external view returns (DetailedUpkeep[] memory) {
        uint256[] memory activeIds = getActiveUpkeepIDs(offset, limit);
        uint256 count = activeIds.length;
        if (offset >= count) return new DetailedUpkeep[](0);
        uint256 to = offset + limit;
        if (count < to) to = count;
        DetailedUpkeep[] memory detailedUpkeeps = new DetailedUpkeep[](to - offset);
        UpkeepInfo[] memory info = getUpkeeps(offset, limit);
        uint96[] memory minAmounts = getMinBalancesForUpkeeps(offset, limit);
        for (uint256 i = 0; i < detailedUpkeeps.length; i++) {
            detailedUpkeeps[i] = DetailedUpkeep(activeIds[i], minAmounts[i], info[i]);
        }
        return detailedUpkeeps;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getUpkeepsCount() external view returns (uint256) {
        return activeUpkeeps.length();
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getState()
        external
        view
        returns (
            State memory state,
            OnchainConfig memory config,
            address[] memory signers,
            address[] memory transmitters,
            uint8 f
        )
    {
        return i_registry.getState();
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function isNewUpkeepNeeded() external view returns (bool isNeeded, uint256 newOffset, uint256 newLimit) {
        uint256 lastActive = activeUpkeeps.length() - 1;
        uint256 lastUpkeepId = activeUpkeeps.at(lastActive);
        UpkeepInfo memory info = i_registry.getUpkeep(lastUpkeepId);
        (uint128 performOffset, uint128 performLimit) = abi.decode(info.checkData, (uint128, uint128));
        (, bytes memory checkResult) = AutomationCompatibleWithViewInterface(info.target).checkUpkeep(info.checkData);
        uint256[] memory performArray = abi.decode(checkResult, (uint256[]));
        isNeeded = performArray.length >= performLimit ? true : false;
        newOffset = performOffset + performLimit;
        newLimit = performLimit;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function checkUpkeep(
        uint256 upkeepId
    )
        public
        returns (
            bool upkeepNeeded,
            bytes memory performData,
            UpkeepFailureReason upkeepFailureReason,
            uint256 gasUsed,
            uint256 fastGasWei,
            uint256 linkNative
        )
    {
        return i_registry.checkUpkeep(upkeepId);
    }
}
