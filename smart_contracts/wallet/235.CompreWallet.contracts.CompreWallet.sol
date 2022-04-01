// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./EIP712MetaTransaction.sol";


contract CompreWallet is Initializable, EIP712MetaTransaction("CompreWallet", "1") {
  /**
   * @notice The user will be the contract owner
   */
  address public owner;

  /**
   * @notice Required parameters for each call
   */
  struct Call {
    address target;
    bytes callData;
    uint256 value;
    bool shouldRevert; // true if whole tx should revert on failure, false otherwise
  }

  /**
   * @notice Emitted when ownership is transferred
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Only let user call a function, either directly or via the GSN-enabled factory
   */
  modifier onlyOwner() {
    require(
      owner == msgSender() || address(this) == msgSender(),
      "CompreWallet: Caller not authorized"
    );
    _;
  }

  /**
   * @notice Replaces constructor to facilitate transition to deployment as minimal proxies
   * @param _user The user who this contract is for
   */
  function initializeWallet(address _user) external initializer {
    emit OwnershipTransferred(address(0), _user);
    owner = _user;
  }

  /**
   * @notice Transfer ownership to a new address
   */
  function transferOwnership(address _newOwner) external onlyOwner {
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  /**
   * @notice Batches a sequence of calls into one transaction
   * @dev Based on the Multicall contract: https://github.com/makerdao/multicall
   * @dev Must be public so it can be called by executeMetaTransaction
   */
  function aggregate(Call[] memory calls)
    public
    onlyOwner
    returns (uint256 blockNumber, bytes[] memory returnData)
  {
    blockNumber = block.number;
    returnData = new bytes[](calls.length);
    for (uint256 i = 0; i < calls.length; i++) {
      (bool ok, bytes memory ret) = calls[i].target.call{value: calls[i].value}(calls[i].callData);
      if (calls[i].shouldRevert) {
        require(ok, "CompreWallet: Call failed");
      }
      returnData[i] = ret;
    }
  }
}
