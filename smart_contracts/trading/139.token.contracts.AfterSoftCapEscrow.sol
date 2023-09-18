pragma solidity 0.4.24;

import 'openzeppelin-solidity/contracts/payment/Escrow.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

/**
 * @title AfterSoftCapEscrow
 * @dev Escrow to only allow withdrawal if a unlocked.
 */
contract AfterSoftCapEscrow is Ownable, Escrow {
  enum State { Active, Refunding, Reached }

  event Reached();
  event WithdrawalsEnabled();
  event RefundsEnabled();

  State public state;
  address public beneficiary;
  uint256 public minimalValue;

  /**
   * @dev Constructor.
   * @param _beneficiary The beneficiary of the deposits.
   */
  constructor(address _beneficiary, uint256 _minimalValue) public {
    require(_beneficiary != address(0));
    beneficiary = _beneficiary;
    state = State.Active;
    minimalValue = _minimalValue;
  }

  /**
   * @dev Stores funds that may later be refunded.
   * @param _refundee The address funds will be sent to if a refund occurs.
   */
  function deposit(address _refundee) public payable {
    require(state != State.Refunding);
    require(msg.value >= 0.0011 ether); // minimal token price (TODO: update for ICO)
    super.deposit(_refundee);
  }

  /**
   * @dev Allows for the beneficiary to withdraw their funds, rejecting
   * further deposits.
   */
  function reachGoal() public onlyOwner {
    require(state == State.Active);
    state = State.Reached;
    emit Reached();
  }

  /**
   * @dev Allows for refunds to take place, rejecting further deposits.
   */
  function enableRefunds() public onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @dev Withdraws the beneficiary's funds.
   */
  function beneficiaryWithdraw() public onlyOwner {
    require(state == State.Reached);
    beneficiary.transfer(address(this).balance);
  }

  function withdraw(address _payee) public {
    require(state == State.Refunding);
    super.withdraw(_payee);
  }
}
