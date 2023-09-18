// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ZAP
 * @author javaadyakuza
 * @notice contract to prevent the zero-address exception
 * @dev the name is actually zeroAddressPreventer but for simplicity we ZAP
 */

contract ZAP {
    modifier nonZeroAddress(address _target) {
        require(_target != address(0), "zero address exception !!");
        _;
    }
}
