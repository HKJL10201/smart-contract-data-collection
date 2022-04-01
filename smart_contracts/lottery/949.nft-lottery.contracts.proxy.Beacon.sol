// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Beacon is IBeacon, Ownable {
    address public impl;
    event ImplementationUpdated(address newImpl);

    constructor(address _owner, address _impl) {
        require(_owner != address(0), "Beacon: ZERO_OWNER_ADDRESS");

        impl = _impl;
        transferOwnership(_owner);
    }

    function changeImpl(address _newImpl) external onlyOwner {
        impl = _newImpl;
        emit ImplementationUpdated(_newImpl);
    }

    function implementation() external view override returns (address) {
        return impl;
    }
}
