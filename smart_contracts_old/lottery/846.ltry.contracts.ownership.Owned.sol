pragma solidity ^0.4.11;

/**
 * Owned contract, some functionality is accessible exclusively by the contract
 * owner. Provides basic access functionality.
 */
contract Owned {
  address public owner;


  /**
   * Sets the owner of the contract to be the contract creator
   */
  function Owned() {
    owner = msg.sender;
  }


  /**
   * Transfers contract ownership
   *
   * @param _newOwner The address of the new contract owner
   */
  function transferOwnership(address _newOwner) onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
  }


  /**
   * Allows only the contract owner to call the modified contract function
   */
  modifier onlyOwner {
    require (msg.sender == owner);
    _;
  }
}
