// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./EIP712MetaTransaction.sol";
import "./CompreWallet.sol";


contract CompreWalletFactory is EIP712MetaTransaction("CompreWalletFactory", "1") {
  /**
   * @notice Store list of all users
   */
  address[] public users;

  /**
   * @notice Maps user => their contract wallet
   */
  mapping(address => address) public getContract;

  /**
   * @notice Emitted when a new wallet is created
   * @param wallet Address of the new wallet
   */
  event WalletCreated(address wallet);

  /**
   * @notice Called to deploy a user's wallet
   */
  function createContract() external {
    // Contract user is the user who sent the meta-transaction
    address _user = msgSender();

    // Deploy proxy
    CompreWallet _compreWallet = new CompreWallet();
    _compreWallet.initializeWallet(_user);

    // Update state
    users.push(_user);
    getContract[_user] = address(_compreWallet);
    emit WalletCreated(address(_compreWallet));
  }

  /**
   * @notice Returns list of all user addresses
   */
  function getUsers() external view returns (address[] memory) {
    return users;
  }
}
