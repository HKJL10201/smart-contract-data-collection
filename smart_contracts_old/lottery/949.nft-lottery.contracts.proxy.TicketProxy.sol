// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract TicketProxy {
    address private immutable beacon;

    constructor(address _beacon) {
        require(_beacon != address(0), "TicketProxy: ZERO_ADDRESS");
        beacon = _beacon;
    }

    fallback() external payable {
        address impl = _implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _implementation() internal view virtual returns (address) {
        return IBeacon(beacon).implementation();
    }
}
