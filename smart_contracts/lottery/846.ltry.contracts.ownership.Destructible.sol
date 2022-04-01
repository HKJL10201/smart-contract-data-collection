pragma solidity ^0.4.11;


import "./Owned.sol";


/**
 * Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Owned {
  function Destructible() payable {}


  /**
   * Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner {
    selfdestruct(owner);
  }


  /**
   * Transfers the current balance to the recipient and terminates the contract.
   *
   * @param _recipient Address to receive the balance
   */
  function destroyAndSend(address _recipient) onlyOwner {
    selfdestruct(_recipient);
  }
}
