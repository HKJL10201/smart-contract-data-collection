// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title disCarbon Devcon 6 attendee pooling contract
/// @author haurog, danceratopz
/// @notice This contract exchanges the coins/tokens of the users for carbon
///         tokens (NCT) and sends them to the pooling address. This contract
///         never owns any coins or tokens as all transactions happen instantly
///         and are forwarded in the same transaction.

contract Devcon_Offset_Pool {
    using SafeERC20 for IERC20;

    /// @notice Stores all contributions (summed up) for each address
    mapping(address => uint256) public contributions;
    /// @notice An array of addresses which have contributed
    address[] public contributorsAddresses;
    /// @notice Sum of all contributions
    uint256 public totalCarbonPooled = 0;
    /// @notice Address to where all the contributions are sent to (to be offset manually later)
    address public poolingAddress = 0x439d22a39cD2d0f0572ed05D3c5081d6117B8031; // Devcon VI multisig

    address private sushiRouterAddress =
        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private NCTAddress = 0xD838290e877E0188a4A44700463419ED96c16107;
    address private WMATICAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private USDCAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    ///@notice Emitted after carbon tokens have been sent to pooling address.
    event ContributionSent(string tokenOrCoin, uint256 carbonTokenContributed);

    ///@dev Needed, otherwise uniswap router for matic fails
    receive() external payable {}

    ///@dev Needed, otherwise uniswap router for matic fails
    fallback() external payable {}

    /// @notice Receives Matic, swaps to carbon token and forwards the swapped
    ///         tokens. Returns any excess Matic.
    /// @param carbonAmount The number of carbon tokens that need to be forwarded.
    function participateWithMatic(uint256 carbonAmount) public payable {
        swapMaticToCarbonToken(carbonAmount);
        doAccounting(carbonAmount);
        forwardCarbonTokenToPool(carbonAmount);
        returnExcessMatic();
        emit ContributionSent("Matic", carbonAmount);
    }

    /// @notice Takes user approved token, swaps to carbon token and forwards
    ///         the swapped tokens. Only takes as many tokens as needed.
    /// @param fromToken Address of the token that should be used to participate.
    /// @param carbonAmount The number of carbon tokens that need to be forwarded.
    function participateWithToken(address fromToken, uint256 carbonAmount)
        public
    {
        if (fromToken == NCTAddress) {
            // Directly transfer NCT tokens.
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                carbonAmount
            );
        } else {
            // for all other tokens do a swap.
            swapTokenToCarbonToken(fromToken, carbonAmount);
        }

        doAccounting(carbonAmount);
        forwardCarbonTokenToPool(carbonAmount);
        emit ContributionSent("Token", carbonAmount);
    }

    ///@notice returns the needed amount of coins/tokens.
    ///         the swapped tokens. Only takes as many tokens as needed.
    /// @param fromToken Address of the token that should be used to participate.
    ///        To estimate Matic tokens, use WMATIC address.
    /// @param carbonAmount Carbon Amount that needs to be purchased.
    /// @return tokenAmountNeeded How many tokens/coins needed for buying the needed
    ///         carbon tokens.
    function calculateNeededAmount(address fromToken, uint256 carbonAmount)
        public
        view
        returns (uint256)
    {
        // if NCT is supplied no swap necessary
        if (fromToken == NCTAddress) {
            return carbonAmount;
        }

        address[] memory path = makePath(fromToken);

        IUniswapV2Router02 sushiRouter = IUniswapV2Router02(sushiRouterAddress);

        uint256[] memory tokenAmountNeeded = sushiRouter.getAmountsIn(
            carbonAmount,
            path
        );

        return tokenAmountNeeded[0];
    }

    /// @notice A getter function for the array with all the contributors addresses.
    /// @return contributorsAddresses An array (can be empty) with all addresses which contributed.
    function getContributorsAddresses() public view returns (address[] memory) {
        return contributorsAddresses;
    }

    /// @notice A function to get the number of contributors.
    /// @return uint256 A number which is the length of the contributorsAddresses array.
    function getContributorsCount() public view returns (uint256) {
        return contributorsAddresses.length;
    }

    /// @notice This function creates a path from the initial token to the final
    ///         token. It always routes the swaps through USDC (Token > USDC > NCT).
    ///         So make sure there is actually liquidity on sushiswap for your token
    ///         for this path.
    /// @param fromToken Address of the token that should be used to participate.
    ///        To estimate Matic tokens, use WMATIC address.
    /// @return path An array with the path for the sushiswap router to do the swap.
    function makePath(address fromToken)
        private
        view
        returns (address[] memory)
    {
        if (fromToken == USDCAddress) {
            address[] memory path = new address[](2);
            path[0] = USDCAddress;
            path[1] = NCTAddress;
            return path;
        } else {
            address[] memory path = new address[](3);
            path[0] = fromToken;
            path[1] = USDCAddress;
            path[2] = NCTAddress;
            return path;
        }
    }

    /// @notice Does the swap for Matic coins.
    function swapMaticToCarbonToken(uint256 carbonAmount) private {
        IUniswapV2Router02 sushiRouter = IUniswapV2Router02(sushiRouterAddress);
        address[] memory path = makePath(WMATICAddress);

        uint256[] memory tokenToSwap = sushiRouter.getAmountsIn(
            carbonAmount,
            path
        );
        require(
            msg.value >= tokenToSwap[0],
            "Not enough Matic to swap to required carbon Token"
        );

        sushiRouter.swapETHForExactTokens{value: msg.value}(
            carbonAmount,
            path,
            address(this),
            block.timestamp
        );
    }

    /// @notice Does the swap for all ERC-20 tokens.
    /// @param fromToken Address of the token one wants to swap to carbon tokens.
    /// @param carbonAmount Amount of carbon tokens one needs.
    function swapTokenToCarbonToken(address fromToken, uint256 carbonAmount)
        private
    {
        IUniswapV2Router02 routerSushi = IUniswapV2Router02(sushiRouterAddress);
        address[] memory path = makePath(fromToken);
        uint256[] memory tokensNeeded = routerSushi.getAmountsIn(
            carbonAmount,
            path
        );
        // transfer tokens to this contract
        IERC20(fromToken).safeTransferFrom(
            msg.sender,
            address(this),
            tokensNeeded[0]
        );
        // approve tokens for sushiRouter
        IERC20(fromToken).approve(sushiRouterAddress, tokensNeeded[0]);
        // swap
        routerSushi.swapTokensForExactTokens(
            carbonAmount,
            tokensNeeded[0],
            path,
            address(this),
            block.timestamp
        );
    }

    /// @notice Does the accounting (storing addresses and values contributed).
    /// @param carbonAmount Amount of carbon tokens contributed.
    function doAccounting(uint256 carbonAmount) private {
        totalCarbonPooled += carbonAmount;
        if (contributions[msg.sender] == 0) {
            contributorsAddresses.push(msg.sender);
        }
        contributions[msg.sender] += carbonAmount;
    }

    /// @notice Returns excess matic not used in the swap.
    function returnExcessMatic() private {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "refund failed");
    }

    /// @notice Forwards the carbon tokens to the pooling Address.
    function forwardCarbonTokenToPool(uint256 carbonAmount) private {
        IERC20(NCTAddress).transfer(poolingAddress, carbonAmount);
    }
}
