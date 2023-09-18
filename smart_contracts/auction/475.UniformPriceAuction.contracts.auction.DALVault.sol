pragma solidity ^0.4.11;

import '../math/SafeMath.sol';
import './DALToken.sol';
import '../crowdsale/RefundVault.sol';

/**
 * @title DALVault
 * @author Master-S
 */
contract DALVault is RefundVault {
  using SafeMath for uint256;

  // The token being sold
  DALToken public token;

  // cumulative counter of token units already claimed
  uint256 public tokensClaimed;
  
  // how many token units a bidder gets per wei
  uint256 public price;
  
  // number of token units owned by DAL Reserve Fund
  uint256 public constant TOKEN_RESERVE = 40000000 * 10**18;
  // maximum number of token units on sale
  uint256 public constant TOKEN_GOAL = 60000000 * 10**18;

  event DALVaultCreated(address wallet, uint256 tokenUnits);
  event PriceSet(uint256 px);
  event Claimed(address beneficiary, uint256 weiAmount, uint256 tokenUnits);

  function DALVault(address _wallet) RefundVault(_wallet) {
    token = new DALToken();
    assert(token.transfer(_wallet, TOKEN_RESERVE));
    DALVaultCreated(_wallet, token.balanceOf(this));
  }

  function setPrice(uint256 _price) onlyOwner {
    require(_price > 0);
    price = _price;
    PriceSet(price);
  }

  function claim(address _beneficiary) onlyOwner {
    require(price > 0);
    uint256 depositedValue = deposited[_beneficiary];
    require(depositedValue > 0);
    uint256 qty = depositedValue.div(price);
    uint256 toClaim = tokensClaimed.add(qty);
    require(toClaim <= TOKEN_GOAL);
    deposited[_beneficiary] = 0;
    assert(token.transfer(_beneficiary, qty));
    tokensClaimed = toClaim;
    Claimed(_beneficiary, depositedValue, qty);
  }

  function close() onlyOwner {
    wallet.transfer(this.balance);
    assert(token.transfer(wallet, token.balanceOf(this)));
    state = State.Closed;
    Closed();
  }
}