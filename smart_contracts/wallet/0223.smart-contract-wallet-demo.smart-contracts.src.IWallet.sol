// SPDX-License-Identifier: MIT only

pragma solidity ^0.8.0;

interface IWallet {

    function owner() external view returns (address);

    function services() external view returns (uint);

    function locked() external view returns (bool);

    function transferOwner(address _newOwner) external;

    function authorised(address _service) external view returns (bool);

    function callEnabled(bytes4 _sig) external view returns (address);

    function addService(address _service) external;

    function revokeService(address _service) external;

    function enableStaticCall(address _module, bytes4 _method) external;

    function init(address _owner, address[] calldata _services) external;

    function lock(bool _lock) external;
}