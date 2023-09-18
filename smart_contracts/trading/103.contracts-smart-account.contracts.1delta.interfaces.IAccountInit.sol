// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IAccountInit {
    function init(
        address _dataProvider,
        address _owner,
        string memory _name,
        bool _enterAndApprove
    ) external;
}
