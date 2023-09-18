// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Privacy.sol";

contract PrivacyAccess {
  using Privacy for Privacy.Access;

  // Contract state
  address private owner;
  Privacy.Access private accessor;
  bool private _isPrivate;

  constructor(address from) {
    owner = from;
    accessor.add(from);
  }

  modifier onlyOwner(address from) {
    require(from == owner, "Not the owner");
    _;
  }
  modifier withAccess(address from) {
    require(hasAccess(from), "had not access");
    _;
  }
  modifier withNoAccess(address from) {
    require(!hasAccess(from), "had access");
    _;
  }

  modifier canAddAccess(address from, address voter){
    require(from == owner, "Not the owner");
    require(_isPrivate, "Cannot alter state if access is public");
    require(voter != owner, "Cannot alter the owner");
    require(!hasAccess(voter), "Proposed voter has access already");
    _;
  }
  modifier canRemoveAccess(address from, address voter){
    require(from == owner, "Not the owner");
    require(_isPrivate, "Cannot alter state if access is public");
    require(voter != owner, "Cannot alter the owner");
    require(hasAccess(voter), "Proposed voter has not access");
    _;
  }

  // Open calls
  function isPrivate() external view returns (bool) {
    return _isPrivate;
  }
  function hasAccess(address voter) public view returns (bool) {
    return accessor.has(voter);
  }
  function togglePrivacy(address from) external onlyOwner(from) {
    _isPrivate = !_isPrivate;
  }

  // Constraint calls
  function addAccess(address from, address voter) external canAddAccess(from, voter) {
    accessor.add(voter);
  }
  function removeAccess(address from, address voter) external canRemoveAccess(from, voter) {
    accessor.remove(voter);
  }
}
