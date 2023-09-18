// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UpgradeableContract {
    address private _implementation;
    address private _admin;

    event Upgraded(address indexed implementation);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin can perform this action");
        _;
    }

    constructor(address implementation_, address admin_) {
        require(implementation_ != address(0), "Invalid implementation address");
        require(admin_ != address(0), "Invalid admin address");

        _implementation = implementation_;
        _admin = admin_;
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function upgrade(address newImplementation) public onlyAdmin {
        require(newImplementation != address(0), "Invalid new implementation address");
        require(newImplementation != _implementation, "New implementation address must be different");

        _implementation = newImplementation;

        emit Upgraded(newImplementation);
    }

    function updateAdmin(address newAdmin) public onlyAdmin {
        _admin = newAdmin;
    }

    fallback() external payable {
        address _impl = _implementation;
        assembly {
            // Copy the incoming calldata to memory
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            // Delegatecall to the implementation contract
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)

            // Copy the return data to memory
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            // Check the delegatecall result
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {
        // Fallback function will be invoked automatically
    }
}