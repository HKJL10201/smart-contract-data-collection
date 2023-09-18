pragma solidity ^0.4.15;


import './lib/MultiSigWallet.sol';


/**
 * @title Frozen wallet - Allow frozen tokens until specified time.
 * @author Sota Ishii - <sot528@gmail.com>
*/
contract FrozenWallet is MultiSigWallet {

  uint256 public thawingTime;

  function FrozenWallet(address[] _owners, uint _required, uint256 _thawingTime)
  public
  validRequirement(_owners.length, _required)
  MultiSigWallet(_owners, _required)
  {
    thawingTime = _thawingTime;
  }

  /// overriding MultiSigWallet#submitTransaction
  /// - To frozen until thawingTime.
  ///
  /// @dev Allows an owner to submit and confirm a transaction.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @return Returns transaction ID.
  function submitTransaction(address destination, uint value, bytes data)
  public
  returns (uint transactionId)
  {
    require(now >= thawingTime);

    return super.submitTransaction(destination, value, data);
  }
}
