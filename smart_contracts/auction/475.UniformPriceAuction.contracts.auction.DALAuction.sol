pragma solidity ^0.4.11;


import '../math/SafeMath.sol';
import '../ownership/Ownable.sol';
import './DALVault.sol';

/**
 * @title DALAuction
 * @author Master-S
 */
contract DALAuction is Ownable {
  using SafeMath for uint256;

  enum Phase { Open, BookFrozen, BookClosed, Settled } 
  Phase public phase;

  // refund vault used to hold funds while auction is running
  DALVault public vault;
  // end of auction timestamp
  uint256 public endTime;

  /**
   * Event for token bid logging
   * @param beneficiary who will get the tokens
   * @param value weis paid for purchase
   */ 
  event Bid(address beneficiary, uint256 value);
  event BookFrozen();
  event BookClosed();
  event Settled();

  modifier atPhase(Phase _phase) {
    require(phase == _phase);
    _;
  }

  modifier beforePhase(Phase _phase) {
    require(phase < _phase);
    _;
  }

  function DALAuction(address _wallet) {
    vault = new DALVault(_wallet); 
    endTime = now + 30 days;
    phase = Phase.Open;
  }

  // fallback function can be used to bid for tokens
  function () payable {
    placeBid();
  }

  // auction bid
  function placeBid() payable beforePhase(Phase.BookClosed) {
    require(msg.value != 0);
    vault.deposit.value(msg.value)(msg.sender);
    Bid(msg.sender, msg.value);
  }

  function freezeBook(uint256 _price) onlyOwner {
    vault.setPrice(_price);
    phase = Phase.BookFrozen;
    BookFrozen();
  }

  // After the book is frozen the bidder can claim tokens here
  function getTokens() atPhase(Phase.BookFrozen) {
    vault.claim(msg.sender);
  }

  // The owner can send tokens here
  function sendTokens(address _beneficiary) onlyOwner {
    vault.claim(_beneficiary);
  }

  /**
   * @dev Must be called after auction ends, to enable refunds
   */
  function closeBook() onlyOwner {
    vault.enableRefunds();
    phase = Phase.BookClosed;
    BookClosed();
  }
  
  // After the book is closed bidders can initiate refunds here
  function getRefund() atPhase(Phase.BookClosed) {
    vault.refund(msg.sender);
  }

  // The owner can send refunds here
  function sendRefund(address _beneficiary) onlyOwner {
    vault.refund(_beneficiary);
  }

  function settleAuction() onlyOwner {
    phase = Phase.Settled;
    vault.close();
    Settled();
  }

  function depositOf(address _beneficiary) constant returns (uint256 balance) {
    return vault.deposited(_beneficiary);
  }

}
