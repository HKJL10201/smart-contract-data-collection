// / contracts/Box.sol
pragma solidity >=0.4.20 <0.6.0;

contract Box {
  uint256 private value;

  // Emitted when the stored value changes
  event ValueChanged(uint256 newValue);

  // Stores a new value in the contract
  function store(uint256 newValue) public {
    value = newValue;
    emit ValueChanged(newValue);
  }

  // Reads the last stored value
  function retrieve() public view returns (uint256) {
    return value;
  }
  // Increments the stored value by 2
  function increment() public {
    value = value + 2;
    emit ValueChanged(value);
  }
}