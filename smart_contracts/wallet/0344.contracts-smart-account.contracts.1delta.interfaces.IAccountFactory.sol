// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IAccountFactory {
    function handleTransferAccount(address _owner, address _newOwner) external;

    function dataProvider() external view returns(address);
}
