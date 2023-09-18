// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin's SafeMath Implementation
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// Importing OpenZeppelin's SafeERC20 Implementation
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract LiquidityPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token1;
    IERC20 public token2;

    // Defining the trading fee in basis points (1 basis point = 0.01%)
    uint256 public constant FEE_BASIS_POINTS = 20;
    uint256 public constant BASIS_POINTS = 10000; 

    // Events for adding/removing liquidity
    event AddLiquidity(address indexed provider, uint256 token1Amount, uint256 token2Amount, uint256 lpTokenAmount);
    event RemoveLiquidity(address indexed provider, uint256 token1Amount, uint256 token2Amount, uint256 lpTokenAmount);

    constructor(address _token1, address _token2) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    function addLiquidity(uint256 _token1Amount, uint256 _token2Amount) external {
        // Transfer tokens from liquidity provider to this contract
        token1.safeTransferFrom(msg.sender, address(this), _token1Amount);
        token2.safeTransferFrom(msg.sender, address(this), _token2Amount);

        // Mint LP tokens to the liquidity provider
        uint256 lpTokenAmount = _token1Amount.add(_token2Amount);
        _mint(msg.sender, lpTokenAmount);

        emit AddLiquidity(msg.sender, _token1Amount, _token2Amount, lpTokenAmount);
    }

    function removeLiquidity(uint256 _lpTokenAmount) external {
        uint256 totalLiquidity = totalSupply();
        // Calculate the amount of tokens to return to the liquidity provider
        uint256 token1Amount = token1.balanceOf(address(this)).mul(_lpTokenAmount).div(totalLiquidity);
        uint256 token2Amount = token2.balanceOf(address(this)).mul(_lpTokenAmount).div(totalLiquidity);

        // Burn LP tokens from the liquidity provider
        _burn(msg.sender, _lpTokenAmount);

        // Transfer tokens from this contract to the liquidity provider
        token1.safeTransfer(msg.sender, token1Amount);
        token2.safeTransfer(msg.sender, token2Amount);

        emit RemoveLiquidity(msg.sender, token1Amount, token2Amount, _lpTokenAmount);
    }

    // Implement a mechanism to limit and control slippage
    // Slippage is controlled by checking that the expected amounts are greater than the minimum amounts specified by the user
    // If the expected amounts are less than the minimum amounts, then the transaction is reverted.
    function checkSlippage(uint256 expectedAmount, uint256 minimumAmount) internal pure {
        require(expectedAmount >= minimumAmount, "Slippage limit exceeded");
    }

    // Implement a more accurate division method that rounds to the nearest integer instead of always rounding down.
    function accurateDivide(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        uint256 result = numerator / denominator;
        if (numerator % denominator >= denominator / 2) {
            result++;
        }
        return result;
    }
}
