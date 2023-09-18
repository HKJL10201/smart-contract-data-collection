// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {KeeperRegistrarInterface} from "./KeeperRegistrarInterface.sol";

interface AutomationCompatibleWithViewInterface {
    /**
     * @notice Checks the upkeep status and provides the necessary data for performing the upkeep.
     * @param checkData Additional data needed to determine the upkeep status.
     * @return upkeepNeeded Indicates whether the upkeep is needed or not.
     * @return performData The data required to perform the upkeep.
     * @dev This function allows users to check the status of an upkeep and obtain the data necessary to perform the upkeep.
     * The checkData parameter contains any additional data required to determine the upkeep status.
     * The function returns a boolean value (upkeepNeeded) indicating whether the upkeep is needed or not.
     * If upkeepNeeded is true, it means the upkeep should be performed.
     * In addition, the function returns performData, which is the data needed to execute the upkeep.
     * Users can use this data to perform the upkeep.
     */
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
}
