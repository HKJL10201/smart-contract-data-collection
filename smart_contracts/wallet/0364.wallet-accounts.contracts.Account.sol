// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./CustomOwnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

contract Account is CustomOwnable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // event Send (address from, address to, uint256 value);

  /* constructor () {
    uint256 balance = address(this).balance;
    if (balance > 0) {
      emit Send(address(0), address(this), balance);
    }
  } */

  receive () external payable {
    // emit Send(msg.sender, address(this), msg.value);
  }

  function transfer (address recipient, address assetAddress, uint256 amount) external onlyOwner nonReentrant {
    // native // ie. null 0x0000000000000000000000000000000000000000
    if (assetAddress == address(0)) {
      amount = amount == 0 ? address(this).balance : amount;
      Address.sendValue(payable(recipient), amount);
      // emit Send(address(this), recipient, amount);
      return;
    }

    // ERC20 // ie. busd 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee
    IERC20 token = IERC20(assetAddress); // + could auto detect if asset address is erc20, etc
    amount = amount == 0 ? token.balanceOf(address(this)) : amount;
    token.safeTransfer(recipient, amount);

    // revert("Unsupported asset type");
  }

  // methods: 0 = swapExactTokensForTokens, 1 = swapExactTokensForETH, 2 = swapExactETHForTokens
  function swap (uint256 method, address router, uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to) external onlyOwner nonReentrant {
    if (method == 0 || method == 1) {
      IERC20 tokenIn = IERC20(path[0]);

      amountIn = amountIn == 0 ? tokenIn.balanceOf(address(this)) : amountIn;

      uint256 allowanceLimit = tokenIn.allowance(address(this), router);
      if (allowanceLimit < amountIn) {
        tokenIn.approve(router, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      }
    } else if (method == 2) {
      amountIn = amountIn == 0 ? address(this).balance : amountIn;
    } else {
      revert("Unsupported method");
    }

    if (method == 0) {
      IUniswapV2Router02(router).swapExactTokensForTokens(amountIn, amountOutMin, path, to, block.timestamp);
    } else if (method == 1) {
      IUniswapV2Router02(router).swapExactTokensForETH(amountIn, amountOutMin, path, to, block.timestamp);
    } else if (method == 2) {
      IUniswapV2Router02(router).swapExactETHForTokens{value: amountIn}(amountOutMin, path, to, block.timestamp);
    } else {
      revert("Unsupported method");
    }
  }
}
