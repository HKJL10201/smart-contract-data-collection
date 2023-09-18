// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './Owned.sol';
import './IWalletContract.sol';

contract WalletContract is Owned, IWalletContract {
  uint public transferCount;

  event transfer(address fromAddress, address toAddress, uint amount, string message, uint256 timestamp);

  mapping(uint => transferStruct) transfers;
  uint256[] transferIds;

  constructor() {
    transferCount = 0;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function createTransfer(address payable toAddress, uint amount, string memory message) public {
    transfers[transferCount] = transferStruct(msg.sender, toAddress, amount, message, block.timestamp);
    transferIds.push(transferCount);
    transferCount++;
    emit transfer(msg.sender, toAddress, amount, message, block.timestamp);
  }

  function getTransfers() public view returns (transferStruct[] memory) {
    transferStruct[] memory _transfers = new transferStruct[](transferCount);
    for (uint256 count = 0; count < transferCount; count++) {
      _transfers[count] = transfers[count];
    }

    return _transfers;
  }
}
