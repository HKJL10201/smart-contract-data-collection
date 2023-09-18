// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "hardhat/console.sol";

error UpkeepManager__NotOwner();
error UpkeepManager__NoAutomationCompatibleContract();

contract UpkeepManager {
    AutomationCompatible s_automationCompatibleContract;
    address immutable i_owner;
    bytes i_callData;
    bool s_isUpkeepNeeded;
    bytes s_performData;

    constructor(bytes memory callData) {
        i_owner = msg.sender;
        i_callData = callData;
    }

    function setAutomationCompatibleContract(
        AutomationCompatible automationCompatibleContract
    ) public onlyOwner {
        s_automationCompatibleContract = AutomationCompatible(
            automationCompatibleContract
        );
    }

    function checkUpkeep() public onlyOwner hasAutomationCompatibleContract {
        (
            bool upkeepNeeded,
            bytes memory performData
        ) = s_automationCompatibleContract.checkUpkeep(i_callData);
        if (upkeepNeeded) {
            s_isUpkeepNeeded = true;
            s_performData = performData;
        }
    }

    function getIsUpkeepNeeded()
        public
        view
        onlyOwner
        returns (bool isUpkeepNeeded)
    {
        isUpkeepNeeded = s_isUpkeepNeeded;
    }

    function performUpkeep() public onlyOwner hasAutomationCompatibleContract {
        s_isUpkeepNeeded = false;
        s_automationCompatibleContract.performUpkeep(s_performData);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert UpkeepManager__NotOwner();
        _;
    }

    modifier hasAutomationCompatibleContract() {
        if (address(s_automationCompatibleContract) == address(0))
            revert UpkeepManager__NoAutomationCompatibleContract();
        _;
    }
}
