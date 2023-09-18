pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

abstract contract ApproveAndCallFallBack {
    function receiveApproval (
        address from, 
        uint256 _amount, 
        address _token, 
        bytes calldata _data) external virtual;
}