pragma solidity ^0.5.9;

import "./Mortal.sol";

contract DaiFaucet is Mortal {

  event Withdrawal (address indexed to, uint amount);
  event Deposit (address indexed from, uint amount);

  /// @notice Give out Dai to anyone who asks
  function withdraw (uint withdraw_amount) public {
      // Limit withdraw amount
      require(withdraw_amount <= 0.1 ether);
      require(daitoken.balanceOf(address(this)) >= withdraw_amount,
                      "Insufficient balance in faucet for withdrawal request");
      // Send the amount to the address that requested it
      daitoken.transfer(msg.sender, withdraw_amount);
      emit Withdrawal(msg.sender, withdraw_amount);
  }
  /// @notice Accept any incoming amount
  function () external payable {
      emit Deposit (msg.sender, msg.value);
  }
}