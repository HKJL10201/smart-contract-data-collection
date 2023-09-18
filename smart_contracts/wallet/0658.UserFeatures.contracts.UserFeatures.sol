
pragma solidity^0.5.2;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

/// @title UserFeatures Contract
/// @author Chris Hill
/// @notice Contract created to implement whitelist and daily spend features.
contract UserFeatures is Ownable {
  using SafeMath for uint256;

  event EtherDeposited(
    address indexed sender,
    uint256 value
  );

  event AddressWhitelisted(
    address indexed whitelistedAddress
  );

  event UserDailySpendChanged(
    uint256 dailySpendValue
  );

  event UserFundsSent(
    address indexed sentAddress,
    uint256 sentValue
  );

  /* 1 Day = 86400 seconds */
  uint256 constant EPOCH_DAY = 86400;

  /* Daily limit parameters */
  uint256 public dailySendLimit;
  uint256 public lastDailyLimitSet;

  /* Struct to hold unique address data */
  struct AddressStruct {
    bool addressWhitelisted;
    uint256 addressDailySpend;
    uint256 addressTotalSpend;
    uint256 addressLastSpendEpochDiv;
  }

  mapping(address => AddressStruct) public addressData;
  address[] public paidAddresses;

  /// @notice Modifier to determine if contract has available funds to send.
  /// @param _requestValue Proposed funds to send to user.
  modifier availableUserFunds(uint256 _requestValue){
    require(address(this).balance > _requestValue);
    _;
  }

  /// @notice Modifier to reset user daily allowance is '1 Day' has passed.
  /// @param _requestAddress Proposed address to send funds to.
  modifier setDailyAllowance(address _requestAddress){
    if(addressData[_requestAddress].addressLastSpendEpochDiv < (now.div(EPOCH_DAY))){
      addressData[_requestAddress].addressDailySpend = 0;
    }
    _;
  }

  /// @notice Constructor to set default contract values.
  /// @param _dailyLimit Starting daily limit for contract use.
  constructor(uint256 _dailyLimit)
  public
  {
    dailySendLimit = _dailyLimit;
    lastDailyLimitSet = 0;
  }

  /// @notice Allow user to control address whitelisting.
  /// @param _address The receiving address to whitelist.
  function whitelistAddress(address _address)
  public
  onlyOwner()
  {
    require(addressData[_address].addressWhitelisted == false, "Address has already been whitelisted");
    addressData[_address].addressWhitelisted = true;
    emit AddressWhitelisted(_address);
  }

  /// @notice Allow user to set daily limit.
  /// @dev Output limit is per non-whitelisted address. Requires a 24 hour cool-off.
  /// @param _newDailyLimit New limit to implement.
  function userSetDailySendLimit(uint256 _newDailyLimit)
  public
  onlyOwner()
  {
    require((now - EPOCH_DAY) > lastDailyLimitSet, "Timeout currently enforced");
    dailySendLimit = _newDailyLimit;
    lastDailyLimitSet = now;
    emit UserDailySpendChanged(_newDailyLimit);
  }

  /// @notice Allow user to send funds from wallet.
  /// @dev _validateSendConditions is called internal to determine if address is WL, daily limit reached.
  /// @dev To determine what a "day" is, (current time in seconds) mod (day in seconds) is used as a comparator.
  /// @param _sendAddress The receiving address.
  /// @param _sendValue The amount of ether to send.
  function sendEtherToAddress(address payable _sendAddress, uint256 _sendValue)
  public
  onlyOwner()
  availableUserFunds(_sendValue)
  setDailyAllowance(_sendAddress)
  {
    require(_validateSendConditions(_sendAddress, _sendValue), "Send conditions are not valid");
    address(_sendAddress).transfer(_sendValue);
    addressData[_sendAddress].addressDailySpend = addressData[_sendAddress].addressDailySpend.add(_sendValue);
    addressData[_sendAddress].addressLastSpendEpochDiv = now.div(EPOCH_DAY);
    addressData[_sendAddress].addressTotalSpend = addressData[_sendAddress].addressTotalSpend.add(_sendValue);
    paidAddresses.push(_sendAddress);
    emit UserFundsSent(_sendAddress, _sendValue);
  }

  /// @notice Internal function to validate send conditions (WL address, daily spend threshold)
  /// @dev To determine what a "day" is, (current time in seconds) div (day in seconds) is used as a comparator.
  /// @param _address The receiving address.
  /// @param _value The amount of ether to send.
  /// @return bool whether send conditions are valid.
  function _validateSendConditions(address _address, uint256 _value)
  internal
  view
  returns (bool)
  {
    uint256 spendThreshold = addressData[_address].addressDailySpend.add(_value);

    if(addressData[_address].addressWhitelisted == false){
      if(spendThreshold > dailySendLimit){
        return false;
      }
    }
    return true;
  }

  function() external payable {
      emit EtherDeposited(msg.sender, msg.value);
  }
}
