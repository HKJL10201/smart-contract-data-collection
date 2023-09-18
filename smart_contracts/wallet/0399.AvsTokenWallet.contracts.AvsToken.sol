pragma solidity ^0.4.22;

import "./StandardToken.sol";
import "./StandardBurnableToken.sol";

contract AvsToken is StandardToken, StandardBurnableToken {

  // STATE DATA
  address private owner;
  string private name = "AvsToken";
  string private symbol = "AvS";
  uint8 private decimals = 2;
  uint256 private INITIAL_SUPPLY = 10000;

  //EVENTS
  event OwnershipTransferred(address indexed currentOwner, address indexed newOwner);
  
  // MODIFIERS
  modifier onlyByOwner() {
      require(msg.sender == owner);
      _;
  }
  
  // CONSTRUCTOR
  constructor() public {
      owner = msg.sender;
      totalSupply_ = INITIAL_SUPPLY;
      balances[msg.sender] = INITIAL_SUPPLY;
  }

  // SETTERS & GETTERS 
  function getName() public view returns (string) {
      return name;
  }

  function getSymbol() public view returns (string) {
      return symbol; 
  }

  function getDecimals() public view returns(uint8) {
      return decimals;
  }

  function setDecimals(uint8 precision) public onlyByOwner returns (uint8, bool) {
      uint8 max = 32; // 2 ** 5

      if (precision > max || precision < 0) return (precision, false);

      decimals = precision;
      return (precision, true);
  }

  // CONTRACT FUNCTIONS
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyByOwner {
      selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyByOwner {
      selfdestruct(_recipient);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyByOwner {
      _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {
      require(_newOwner != address(0));
      emit OwnershipTransferred(owner, _newOwner);
      owner = _newOwner;
  }
  
}
