pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol';
import 'openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

/**
 * @title PostDeliveryCrowdsale. Custom Implementation to fix bug for preallocated token sales
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
contract PostDeliveryCrowdsale is TimedCrowdsale, FinalizableCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;
  uint256 public totalTokensSold = 0;
  uint256 private hardCap;

  /**
   * @param _hardCap hard cap in tokens
   */
  constructor (uint256 _hardCap) public {
    hardCap = _hardCap;
  }

  function balanceOf (address _address) public view returns (uint256) {
    return balances[_address];
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends and crowdsale is finalized.
   */
  function withdrawTokens() public {
    require(hasClosed());
    require(isFinalized);
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
  }

  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    require(totalTokensSold.add(_tokenAmount) <= hardCap);
    totalTokensSold.add(_tokenAmount);
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }
}
