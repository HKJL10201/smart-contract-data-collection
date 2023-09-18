pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice NEC Auction Engine
contract SimpleNEC is ERC20 {

  function burnAndRetrieve(uint256 _tokensToBurn) public returns (bool success) {
      _burn(msg.sender, _tokensToBurn);
      success = true;
  }

  function mint(address account, uint256 amount) public returns (bool success) {
      _mint(account, amount);
      success = true;
  }
}
