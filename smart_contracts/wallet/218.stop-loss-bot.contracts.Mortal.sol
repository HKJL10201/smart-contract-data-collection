pragma solidity ^0.5.9;

import "./Owned.sol";

contract Mortal is Owned {
  /// @notice only Owner can shutdown this contract
  function destroy() public onlyOwner {
    daitoken.transfer(owner, daitoken.balanceOf(address(this)));
    selfdestruct(msg.sender);
  }
}