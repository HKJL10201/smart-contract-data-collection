// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AutomationRegistryExecutableInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";

interface AutomationRegistryWithMinANeededAmountInterface is AutomationRegistryExecutableInterface {
    /**
     * @notice Retrieves the minimum balance required for a specific upkeep.
     * @param upkeepId The unique identifier (ID) of the upkeep.
     * @return The minimum balance required for the specified upkeep.
     * @dev This function allows users to retrieve the minimum balance required to perform a specific upkeep.
     * The minimum balance represents the amount of funds that need to be available in the contract in order to execute the upkeep successfully.
     * The upkeep ID is used to identify the specific upkeep for which the minimum balance is being retrieved.
     */
    function getMinBalanceForUpkeep(uint256 upkeepId) external view returns (uint96);
}
