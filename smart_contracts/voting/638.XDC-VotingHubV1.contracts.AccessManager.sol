// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

contract AccessManager {
    /// @notice authorized addresses with proposal management privileges
    mapping(address => bool) public authorized;

    /// @notice contract owner
    address public owner;

    /// @notice An event emitted when this contract ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);   

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner == msg.sender);
        _;
    }

    function isAuthorized(address _address) public view returns (bool) {
        return authorized[_address];
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0), "Authorizable: new authority is the zero address");
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != address(0), "Authorizable: new authority is the zero address");
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "Contract is not allowed to use this function");
        require(msg.sender == tx.origin, "Proxy contract is not allowed to use this function");
       _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
