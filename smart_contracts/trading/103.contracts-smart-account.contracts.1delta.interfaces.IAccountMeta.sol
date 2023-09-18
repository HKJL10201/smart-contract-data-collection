// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

struct AccountMetadata {
    address accountAddress;
    address accountOwner;
    string accountName;
    uint256 creationTimestamp;
}

interface IAccountMeta {
    function fetchAccountMetadata() external view returns (AccountMetadata memory);
}
