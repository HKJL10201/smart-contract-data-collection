// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IWalletContract {
  struct transferStruct {
    address fromAddress;
    address toAddress;
    uint amount;
    string message;
    uint256 timestamp;
  }

  function createTransfer(address payable toAddress, uint amount, string memory message) external;
  function getTransfers() external view returns (transferStruct[] memory);
}
