// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IProvider {
    function get_address(uint256 _id) external view returns (address);
}