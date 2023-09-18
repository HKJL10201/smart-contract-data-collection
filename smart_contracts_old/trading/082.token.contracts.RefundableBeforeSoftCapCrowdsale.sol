pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

import './AfterSoftCapEscrow.sol';

/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 */
contract RefundableBeforeSoftCapCrowdsale is Ownable, FinalizableCrowdsale {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund escrow used to hold funds while crowdsale is running
  // AfterSoftCapEscrow private escrow;
  AfterSoftCapEscrow private escrow;

  /**
   * @dev Constructor, creates RefundEscrow.
   * @param _goal Funding goal
   */
  constructor(uint256 _goal) public {
    require(_goal > 0);
    escrow = new AfterSoftCapEscrow(wallet, rate);
    goal = _goal;
  }

  /**
   * @dev Investors can claim refunds here if crowdsale is unsuccessful
   */
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    escrow.withdraw(msg.sender);
  }

  /**
   * @dev Checks escrow wallet balance
   */
  function escrowBalance() public view returns (uint256) {
    return address(escrow).balance;
  }

  /**
   * @dev Checks whether funding goal was reached.
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }
  
  function updateEscrowGoalReached() onlyOwner public {
    require(!isFinalized);
    require(goalReached());

    escrow.reachGoal();
  }

  function beneficiaryWithdraw() onlyOwner public {
    require(goalReached());

    escrow.beneficiaryWithdraw();
  }

  /**
   * @dev escrow finalization task, called when owner calls finalize()
   */
  function finalization() internal {
    if (goalReached()) {
      escrow.reachGoal();
      escrow.beneficiaryWithdraw();
    } else {
      escrow.enableRefunds();
    }

    super.finalization();
  }

  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to escrow.
   */
  function _forwardFunds() internal {
    escrow.deposit.value(msg.value)(msg.sender);
  }

}
