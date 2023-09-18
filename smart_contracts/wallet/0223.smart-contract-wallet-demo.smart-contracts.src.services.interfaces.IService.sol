// SPDX-License-Identifier: MIT only

pragma solidity ^0.8.0;

interface IService {
    function addService(address _wallet, address _module) external;

    function init(address _wallet) external;

    function supportsStaticCall(bytes4 _methodId) external view returns (bool _isSupported);
}