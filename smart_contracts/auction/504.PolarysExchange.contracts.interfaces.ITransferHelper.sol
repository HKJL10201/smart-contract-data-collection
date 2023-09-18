// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferHelper {
    function addOperator(address _operator) external;

    function removeOperator(address _operator) external;

    function executeERC721Transfer(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function executeERC20Transfer(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function executeERC20TransferBack(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) external;

    function executeERC1155Transfer(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}
