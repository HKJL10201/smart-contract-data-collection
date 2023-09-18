// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/governance/GovernanceToken.sol";

contract Treasury is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TIME_LOCK = keccak256("TIME_LOCK");
    uint256 totalBalance = 0;

    // regsiterd modules to access treasury
    struct Module {
        bool isRegistered;
        uint balance;
    }

    mapping(address => Module) public modules;
    address public tokenAddress;

    event ValueReceived(address user, uint amount);

    constructor(address _tokenAddress, address _moduleAddress) {
        tokenAddress = _tokenAddress;
        _grantRole(TIME_LOCK, tokenAddress);
        _grantRole(PAUSER_ROLE, msg.sender);
        modules[_moduleAddress] = Module({isRegistered: true, balance: 0});
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev Function setRoleAdmin
    /// @param _role  getRoleAdmin -> returns bytes32 "NEED_MODULE_ADMIN"
    /// @param _newAdminRole timeLock will update the target ratio whenever necessary
    function setRoleAdmin(
        bytes32 _role,
        bytes32 _newAdminRole
    ) external onlyRole(getRoleAdmin(_role)) {
        _setRoleAdmin(_role, _newAdminRole);
    }

    // Community/Commette votes on new modules to access treasury
    function _registerModule(
        address moduleAddress
    ) internal virtual onlyRole(TIME_LOCK) {
        require(
            !modules[moduleAddress].isRegistered,
            "Address already registered."
        );
        modules[moduleAddress] = Module({isRegistered: true, balance: 0});
    }

    function _unregisterModule(
        address moduleAddress
    ) internal virtual onlyRole(TIME_LOCK) {
        require(modules[moduleAddress].isRegistered, "Address Not registered.");
        modules[moduleAddress].isRegistered = false;
    }

    // function _moduleDeposit() external payable onlyRole(TIME_LOCK) {
    //     GovernanceToken token = GovernanceToken(tokenAddress);
    //     require(token.transfer(address(this), msg.value), "Transfer failed!");
    // }

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    fallback() external payable {}

}
