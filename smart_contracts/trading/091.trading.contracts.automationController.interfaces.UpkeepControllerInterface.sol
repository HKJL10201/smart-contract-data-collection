// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {UpkeepInfo, State, OnchainConfig, UpkeepFailureReason} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";
import {AutomationRegistryExecutableInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";
import {KeeperRegistrarInterface} from "./KeeperRegistrarInterface.sol";

interface UpkeepControllerInterface {
    /**
     * @notice Represents a detailed upkeep containing information about an upkeep,
     * including its ID, minimum amount, and additional upkeep information.
     * @param id The ID of the upkeep.
     * @param minAmount The minimum amount required for the upkeep.
     * @param info The UpkeepInfo struct containing detailed information about the upkeep.
     * @dev This struct is used to encapsulate detailed information about an upkeep,
     * including its  relevant details.
     */
    struct DetailedUpkeep {
        uint256 id;
        uint96 minAmount;
        UpkeepInfo info;
    }

    /**
     * @notice Emitted when a new upkeep is created.
     * @param id The ID of the created upkeep.
     * @dev This event is emitted when a new upkeep.
     */
    event UpkeepCreated(uint256 indexed id);

    /**
     * @notice Emitted when an upkeep is canceled.
     * @param id The ID of the canceled upkeep.
     * @dev This event is emitted when an upkeep is canceled.
     */
    event UpkeepCanceled(uint256 indexed id);

    /**
     * @notice Emitted when an upkeep is paused.
     * @param id The ID of the paused upkeep.
     * @dev This event is emitted when an upkeep is paused.
     */
    event UpkeepPaused(uint256 indexed id);

    /**
     * @notice Emitted when an upkeep is unpaused.
     * @param id The ID of the unpaused upkeep.
     * @dev This event is emitted when an upkeep is unpaused.
     */
    event UpkeepUnpaused(uint256 indexed id);

    /**
     * @notice Emitted when an upkeep is updated.
     * @param id The ID of the updated upkeep.
     * @param newCheckData The new check data for the upkeep.
     * @dev This event is emitted when an upkeep is updated, with the new check data included.
     */

    event UpkeepUpdated(uint256 indexed id, bytes newCheckData);
    /**
     * @notice Emitted when funds are added to an upkeep.
     * @param id The ID of the upkeep to which funds are added.
     * @param amount The amount of funds added to the upkeep.
     * @dev This event is emitted when funds are added to an upkeep.
     */

    event FundsAdded(uint256 indexed id, uint96 amount);
    /**
     * @notice Emitted when the gas limit is set for an upkeep.
     * @param id The ID of the upkeep for which the gas limit is set.
     * @param amount The gas limit value set for the upkeep.
     * @dev This event is emitted when the gas limit is set for an upkeep.
     */

    event UpkeepGasLimitSet(uint256 indexed id, uint32 amount);

    /**
     * @notice Emitted when the off-chain configuration is set for an upkeep.
     * @param id The ID of the upkeep for which the off-chain configuration is set.
     * @param config The off-chain configuration data set for the upkeep.
     * @dev This event is emitted when the off-chain configuration is set for an upkeep.
     */
    event UpkeepOffchainConfigSet(uint256 indexed id, bytes config);

    /**
     * @notice Registers a new upkeep and predicts its ID.
     * @param params The registration parameters for the upkeep.
     * @dev The caller must approve the transfer of LINK tokens to this contract before calling this function.
     * @dev This function transfers the specified amount of LINK tokens from the caller to this contract.
     * @dev It then approves the transfer of LINK tokens to the KeeperRegistrar contract.
     * @dev Next, it calls the registerUpkeep function of the KeeperRegistrar contract to register the upkeep.
     * @dev If the upkeep is successfully registered, the upkeep ID is added to the activeUpkeeps set and an UpkeepCreated event is emitted.
     * @dev If the upkeep registration fails, the function reverts with an error message.
     * @dev Emits a {UpkeepCreated} event.
     */
    function registerAndPredictID(KeeperRegistrarInterface.RegistrationParams memory params) external;

    /**
     * @notice Cancel an active upkeep.
     * @param upkeepId The ID of the upkeep to cancel.
     * @dev The upkeep must be active.
     * @dev This function calls the cancelUpkeep function of the AutomationRegistry contract to cancel the upkeep.
     * @dev It removes the upkeep ID from the activeUpkeeps set.
     * @dev Emits a {UpkeepCanceled} event.
     */
    function cancelUpkeep(uint256 upkeepId) external;

    /**
     * @notice Pauses an active upkeep.
     * @param upkeepId The ID of the upkeep to pause.
     * @dev The upkeep must be active.
     * @dev This function calls the pauseUpkeep function of the AutomationRegistry contract to pause the upkeep.
     * @dev It removes the upkeep ID from the activeUpkeeps set, adds it to the pausedUpkeeps set.
     * @dev Emits a {UpkeepPaused} event.
     */
    function pauseUpkeep(uint256 upkeepId) external;

    /**
     * @notice Unpauses a paused upkeep.
     * @param upkeepId The ID of the upkeep to unpause.
     * @dev The upkeep must be paused.
     * @dev This function calls the unpauseUpkeep function of the AutomationRegistry contract to unpause the upkeep.
     * @dev It removes the upkeep ID from the pausedUpkeeps set, adds it to the activeUpkeeps set.
     * @dev Emits a {UpkeepUnpaused} event.
     */
    function unpauseUpkeep(uint256 upkeepId) external;

    /**
     * @notice Updates the check data of an upkeep.
     * @param upkeepId The ID of the upkeep to update.
     * @param newCheckData The new check data to set for the upkeep.
     * @dev The upkeep must be an active upkeep.
     * @dev This function calls the updateCheckData function of the AutomationRegistryWithMinANeededAmount contract to update the check data of the upkeep.
     * @dev Emits a {UpkeepUpdated} event.
     */
    function updateCheckData(uint256 upkeepId, bytes memory newCheckData) external;

    /**
     * @notice Update the gas limit for an specific upkeep.
     * @param upkeepId The ID of the upkeep to set the gas limit for.
     * @param gasLimit The gas limit to set for the upkeep.
     * @dev The upkeep must be active.
     * @dev This function calls the setUpkeepGasLimit function of the AutomationRegistry
     * contract to set the gas limit for the upkeep.
     * @dev Emits a {UpkeepGasLimitSet} event.
     */
    function setUpkeepGasLimit(uint256 upkeepId, uint32 gasLimit) external;

    /**
     * @notice Update the off-chain configuration for an upkeep.
     * @param upkeepId The ID of the upkeep to set the off-chain configuration for.
     * @param config The off-chain configuration data to set for the upkeep.
     * @dev The upkeep must be active.
     * @dev This function calls the setUpkeepOffchainConfig function of the AutomationRegistry contract
     * to set the off-chain configuration for the upkeep.
     * @dev Emits a {UpkeepOffchainConfigSet} event.
     */
    function setUpkeepOffchainConfig(uint256 upkeepId, bytes calldata config) external;

    /**
     * @notice Adds funds to an upkeep.
     * @param upkeepId The ID of the upkeep to add funds to.
     * @param amount The amount of funds to add to the upkeep.
     * @dev The upkeep must be active.
     * @dev This function transfers the specified amount of LINK tokens from the caller to the contract.
     * @dev It approves the transferred LINK tokens for the AutomationRegistry contract
     * and calls the addFunds function of the AutomationRegistry contract to add funds to the upkeep.
     * @dev Emits a {FundsAdded} event.
     */
    function addFunds(uint256 upkeepId, uint96 amount) external;

    /**
     * @notice Retrieves the information of an upkeep.
     * @param upkeepId The ID of the upkeep to retrieve information for.
     * @return upkeepInfo The UpkeepInfo struct containing the information of the upkeep.
     * @dev This function calls the getUpkeep function of the AutomationRegistry contract to retrieve the information of the upkeep.
     */
    function getUpkeep(uint256 upkeepId) external view returns (UpkeepInfo memory upkeepInfo);

    /**
     * @notice Retrieves the IDs of active upkeeps within a specified range.
     * @param offset The starting index of the range.
     * @param limit The maximum number of IDs to retrieve.
     * @return upkeeps An array of active upkeep IDs within the specified range.
     * @dev This function returns an array of active upkeep IDs, starting from the offset and up to the specified limit.
     * @dev If the offset exceeds the total number of active upkeeps, an empty array is returned.
     * @dev This function uses the activeUpkeeps set to retrieve the IDs.
     */
    function getActiveUpkeepIDs(uint256 offset, uint256 limit) external view returns (uint256[] memory upkeeps);

    /**
     * @notice Retrieves a batch of upkeeps with their information.
     * @param offset The starting index of the range.
     * @param limit The maximum number of upkeeps to retrieve.
     * @return upkeeps An array of UpkeepInfo structs containing the information of the retrieved upkeeps.
     * @dev This function retrieves a batch of upkeeps by calling the getActiveUpkeepIDs function
     * to get the IDs of active upkeeps within the specified range.
     * @dev It then iterates over the retrieved IDs and calls the getUpkeep function of the AutomationRegistry contract
     * to retrieve the information of each upkeep.
     */
    function getUpkeeps(uint256 offset, uint256 limit) external view returns (UpkeepInfo[] memory);

    /**
     * @notice Retrieves the minimum balance required for an upkeep.
     * @param upkeepId The ID of the upkeep to retrieve the minimum balance for.
     * @return minBalance The minimum balance required for the upkeep.
     * @dev This function calls the getMinBalanceForUpkeep function of the AutomationRegistry contract
     * to retrieve the minimum balance required for the upkeep.
     */
    function getMinBalanceForUpkeep(uint256 upkeepId) external view returns (uint96);

    /**
     * @notice Retrieves the minimum balances required for a batch of upkeeps.
     * @param offset The starting index of the range.
     * @param limit The maximum number of upkeeps to retrieve minimum balances for.
     * @return minBalances An array of minimum balances required for the retrieved upkeeps.
     * @dev This function retrieves a batch of upkeeps by calling the getActiveUpkeepIDs function
     * to get the IDs of active upkeeps within the specified range.
     * @dev It then iterates over the retrieved IDs and calls the getMinBalanceForUpkeep function of the AutomationRegistry contract
     * to retrieve the minimum balance for each upkeep.
     */

    function getMinBalancesForUpkeeps(uint256 offset, uint256 limit) external view returns (uint96[] memory);

    /**
     * @notice Retrieves a batch of detailed upkeeps.
     * @param offset The starting index of the range.
     * @param limit The maximum number of detailed upkeeps to retrieve.
     * @return detailedUpkeeps An array of DetailedUpkeep structs containing the information of the retrieved detailed upkeeps.
     * @dev This function retrieves a batch of upkeeps by calling the getActiveUpkeepIDs function
     * to get the IDs of active upkeeps within the specified range.
     * @dev It then calls the getUpkeeps and getMinBalancesForUpkeeps functions to retrieve the information and minimum balances for the upkeeps.
     * @dev Finally, it combines the information into DetailedUpkeep structs and returns an array of detailed upkeeps.
     */
    function getDetailedUpkeeps(uint256 offset, uint256 limit) external view returns (DetailedUpkeep[] memory);

    /**
     * @notice Retrieves the total number of active upkeeps.
     * @return count The total number of active upkeeps.
     * @dev This function returns the length of the activeUpkeeps set, representing the total number of active upkeeps.
     */
    function getUpkeepsCount() external view returns (uint256);

    /**
     * @notice Retrieves the current state, configuration, signers, transmitters, and flag from the registry.
     * @return state The State struct containing the current state of the registry.
     * @return config The OnchainConfig struct containing the current on-chain configuration of the registry.
     * @return signers An array of addresses representing the signers associated with the registry.
     * @return transmitters An array of addresses representing the transmitters associated with the registry.
     * @return f The flag value associated with the registry.
     * @dev This function calls the getState function of the AutomationRegistry contract
     * to retrieve the current state, configuration, signers, transmitters, and flag.
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
        );

    /**
     * @notice Checks if a new upkeep is needed and returns the offset and limit for the next of upkeep.
     * @return isNeeded A boolean indicating whether a new upkeep is needed.
     * @return newOffset The offset value for the next upkeep.
     * @return newLimit The limit value for the next upkeep.
     * @dev This function calculates the offset and limit for the next upkeep based on the last active upkeep.
     * @dev It retrieves the last active upkeep ID and the associated performOffset and performLimit from the registry.
     * @dev It then calls the checkUpkeep function of the AutomationCompatible contract to perform the upkeep check.
     * @dev The result is used to determine whether a new upkeep is needed,
     * and the new offset and limit values for the next upkeep are calculated.
     */
    function isNewUpkeepNeeded() external view returns (bool isNeeded, uint256 newOffset, uint256 newLimit);

    /**
     * @notice Performs the upkeep check for a specific upkeep.
     * @param upkeepId The ID of the upkeep to check.
     * @return upkeepNeeded A boolean indicating whether the upkeep is needed.
     * @return performData The perform data associated with the upkeep.
     * @return upkeepFailureReason The reason for the upkeep failure, if applicable.
     * @return gasUsed The amount of gas used during the upkeep check.
     * @return fastGasWei The wei value for fast gas during the upkeep check.
     * @return linkNative The amount of LINK or native currency used during the upkeep check.
     * @dev This function calls the checkUpkeep function of the AutomationRegistry contract
     * to perform the upkeep check for the specified upkeep.
     */
    function checkUpkeep(
        uint256 upkeepId
    )
        external
        returns (
            bool upkeepNeeded,
            bytes memory performData,
            UpkeepFailureReason upkeepFailureReason,
            uint256 gasUsed,
            uint256 fastGasWei,
            uint256 linkNative
        );
}
