// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DeadManSwitch is Initializable{
    event Switch(uint256 switchTriggerBlockDiff, address switchAccount);
    event SwitchRequest(uint256 switchRequestBlockNumber);

    uint256 public switchRequestBlockNumber;
    uint256 public switchTriggerBlockDiff;
    bool public switchActivated;
    address public switchAccount;


    function DeadManSwitch__init() internal {
        switchRequestBlockNumber = ~uint256(0);
    }

    modifier ifSwitchActivated() {
        require(switchActivated);
        _;
    }

    modifier ifSwitchNotActivated() {
        require(!switchActivated);
        _;
    }

    modifier onlySwitchAccount() {
        _onlySwitchAccount();
        _;
    }

    function _onlySwitchAccount() internal view {
        //directly from EOA owner, or through the entryPoint (which gets redirected through execFromEntryPoint)
        require(
            msg.sender == switchAccount && msg.sender == address(this),
            "only switch account"
        );
    }

    modifier _canSwitchActivate() {
        require(!switchActivated);
        require(
            (block.number - switchRequestBlockNumber) >= switchTriggerBlockDiff,
            "cannot activate switch"
        );
        _;
    }

    function _activateSwitch() internal _canSwitchActivate {
        switchActivated = true;
    }

    function _setSwitch(address account, uint256 diff) internal {
        switchAccount = account;
        switchTriggerBlockDiff = diff;
        emit Switch(switchTriggerBlockDiff, switchAccount);
    }

    function _setSwitchRequest() internal {
        switchRequestBlockNumber = block.number;
        emit SwitchRequest(switchRequestBlockNumber);
    }

    function _rejectSwitchRequest() internal {
        switchRequestBlockNumber = ~uint256(0);
    }
}
