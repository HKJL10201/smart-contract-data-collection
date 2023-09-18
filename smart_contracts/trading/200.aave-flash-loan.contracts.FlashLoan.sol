// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

error FlashLoan__NotOwner();

contract FlashLoan is FlashLoanSimpleReceiverBase {
    address private immutable i_owner;

    modifier onlyOwner() {
        if (msg.sender != i_owner) { revert FlashLoan__NotOwner(); }
        _;
    }

    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        i_owner = msg.sender;
    }

    function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address /*initiator*/,
    bytes calldata /*params*/
  ) external override returns (bool) {
    uint256 amountOwed = amount + premium;
    IERC20(asset).approve(address(POOL), amountOwed);

    return true; 
  }

  function requestFlashLoan(address _token, uint256 _amount) public {
    address receiverAddress = address(this);
    address asset = _token;
    uint256 amount = _amount;
    bytes memory params= "";
    uint16 referralCode = 0;

    POOL.flashLoanSimple(receiverAddress, asset, amount, params, referralCode);
  }

  function withdraw(address _tokenAddress) external onlyOwner {
    IERC20 token = IERC20(_tokenAddress);
    token.transfer(payable(msg.sender), token.balanceOf(address(this)));
  }

  function getBalance(address _tokenAddress) external view returns (uint256) {
    return IERC20(_tokenAddress).balanceOf(address(this));
  }

  receive() external payable {}
}
 