// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Admin is Ownable {
  // function initialize() public initializer {
  //   __Ownable_init();
  // }

  struct AdminInfo {
    uint256 index; // one base index
    uint8 adminType;
    bool status;
  }

  address[] private admins;
  mapping(address => AdminInfo) addrToAdmin;

  event AdminAdded(address _wallet, uint8 _adminType);
  event AdminUpdated(address _wallet, uint8 _adminType);
  event AdminStatusChanged(address _wallet, bool _status);
  event AdminRemoved(address _wallet);

  modifier validAddress(address _wallet) {
    require(_wallet != address(0), "Address can't be 0");
    _;
  }

  modifier notOwner(address _wallet) {
    require(_wallet != owner(), "Address can't be owner");
    _;
  }

  function isExisted(address _wallet) public view returns (bool) {
    return addrToAdmin[_wallet].index > 0;
  }

  function addAdmin(address _wallet, uint8 _adminType) external onlyOwner validAddress(_wallet) notOwner(_wallet) {
    require(!isExisted(_wallet), "Address already existed");
    admins.push(_wallet);
    addrToAdmin[_wallet].index = admins.length;
    addrToAdmin[_wallet].adminType = _adminType;
    addrToAdmin[_wallet].status = true;
    emit AdminAdded(_wallet, _adminType);
  }

  function deactiveAdmin(address _wallet) external onlyOwner validAddress(_wallet) notOwner(_wallet) {
    require(addrToAdmin[_wallet].status, "Address already deactivated");
    addrToAdmin[_wallet].status = false;
    emit AdminStatusChanged(_wallet, false);
  }

  function activateAdmin(address _wallet) external onlyOwner validAddress(_wallet) notOwner(_wallet) {
    require(!addrToAdmin[_wallet].status, "Address already activated");
    addrToAdmin[_wallet].status = true;
    emit AdminStatusChanged(_wallet, true);
  }

  function getAdminType(address _wallet) external validAddress(_wallet) view returns (uint8) {
    require(isExisted(_wallet), "Address doesn't exist");
    return addrToAdmin[_wallet].adminType;
  }

  function updateAdminType(address _wallet, uint8 _adminType) external validAddress(_wallet) notOwner(_wallet) {
    require(_adminType != addrToAdmin[_wallet].adminType, "Admin type can't be the same");
    addrToAdmin[_wallet].adminType = _adminType;
    emit AdminUpdated(_wallet, _adminType);
  }

  function removeAdmin(address _wallet) external validAddress(_wallet) notOwner(_wallet) {
    require(isExisted(_wallet), "Address does not exist");
    // Remove address from array
    // Index is 1 base, and array is 0 base
    // Move the last array to the current array, then pop the last array
    admins[addrToAdmin[_wallet].index - 1] = admins[admins.length - 1];
    admins.pop();

    // Change mapping value
    addrToAdmin[_wallet].index = 0;
    addrToAdmin[_wallet].adminType = 0;
    addrToAdmin[_wallet].status = false;

    emit AdminRemoved(_wallet);
  }

  function isAdmin(address _wallet) public view validAddress(_wallet) returns (bool) {
    return addrToAdmin[_wallet].index > 0;
  }
}
