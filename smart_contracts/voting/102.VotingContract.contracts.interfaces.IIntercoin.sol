// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IIntercoin {
    
    function registerInstance(address addr) external returns(bool);
    function checkInstance(address addr) external view returns(bool);
    
}
