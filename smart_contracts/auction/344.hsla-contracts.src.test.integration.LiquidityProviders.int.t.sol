// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20Upgradeable.sol";
import "../../interfaces/compound/ICERC20.sol";
import "../../interfaces/compound/ICEther.sol";
import "../../Liquidity.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IWETH.sol";
import "../common/BaseTest.sol";

// @dev These tests are intended to be run against a forked mainnet.

contract LiquidityProvidersIntegrationTest is BaseTest {
    IUniswapV2Router SushiSwapRouter;
    IWETH WETH;
    IERC20Upgradeable DAI;
    ICERC20 cDAI;
    ICEther cETH;
    NiftyApesLiquidity liquidityProviders;

    // This is needed to receive ETH when calling `withdrawEth`
    receive() external payable {}

    function setUp() public {
        // Setup WETH
        WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        // Setup DAI
        DAI = IERC20Upgradeable(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        // Setup SushiSwapRouter
        SushiSwapRouter = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

        // Setup cETH and balances
        cETH = ICEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
        // Mint 10k ether in cETH
        cETH.mint{ value: 10000 ether }();

        // Setup DAI balances

        // There is another way to do this using HEVM cheatcodes like so:
        //
        // IEVM.store(address(DAI), 0xde88c4128f6243399c8c224ee49c9683b554a068089998cb8cf2b7c8a19de28d, bytes32(uint256(100000 ether)));
        //
        // but I didn't figure out how to easily calculate the
        // storage addresses for the deployed test contracts or approvals, so I just used a deployed router.

        // So, we get some DAI with Sushiswap.
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(DAI);
        // Let's trade for 100k dai
        SushiSwapRouter.swapExactETHForTokens{ value: 100000 ether }(
            100 ether,
            path,
            address(this),
            block.timestamp + 1000
        );

        // Setup cDAI and balances
        // Point at the real compound DAI token deployment
        cDAI = ICERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        // Mint 50k DAI in cDAI
        DAI.approve(address(cDAI), 50000 ether);
        cDAI.mint(50000 ether);

        // Setup the liquidity providers contract
        liquidityProviders = new NiftyApesLiquidity();
        // Allow assets for testing
        liquidityProviders.setCAssetAddress(address(DAI), address(cDAI));
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cETH)
        );
        uint256 max = type(uint256).max;

        // Approve spends
        DAI.approve(address(liquidityProviders), max);
        cDAI.approve(address(liquidityProviders), max);
        cETH.approve(address(liquidityProviders), max);

        //For some reason if this following value supplied is 100k then supplyCErc20() fails.
        //Seems to be something around cerc20 balance or comptroller rejecting the transaction

        // Supply to 10k DAI to contract
        liquidityProviders.supplyErc20(address(DAI), 10000 ether);
        // Supply 10k ether to contract
        liquidityProviders.supplyEth{ value: 10000 ether }();
    }

    // Test cases

    // TODO(Add assertions around expected event emissions)
    // TODO(Create failing tests/assertions for each function)

    // function testSupplyErc20(uint32 deposit) public {
    //     IERC20 underlying = IERC20(DAI);
    //     ICERC20 cToken = ICERC20(cDAI);

    //     uint256 assetBalanceInit = underlying.balanceOf(address(this));

    //     uint256 cAssetBalanceInit = liquidityProviders.getCAssetBalance(
    //         address(this),
    //         address(cDAI)
    //     );

    //     liquidityProviders.supplyErc20(address(DAI), deposit);

    //     (, uint256 mintTokens) = divScalarByExpTruncate(
    //         deposit,
    //         Exp({ mantissa: cToken.exchangeRateCurrent() })
    //     );

    //     uint256 assetBalance = underlying.balanceOf(address(this));

    //     uint256 cAssetBalance = liquidityProviders.getCAssetBalance(address(this), address(cDAI));

    //     assert(assetBalance == (assetBalanceInit - deposit));
    //     assert(cAssetBalance == (cAssetBalanceInit + mintTokens));
    //     assert(cAssetBalance == cToken.balanceOf(address(liquidityProviders)));
    // }

    // function testSupplyCErc20(uint256 deposit) public {
    //     uint256 cAssetBalanceInit = liquidityProviders.getCAssetBalance(
    //         address(this),
    //         address(cDAI)
    //     );

    //     if (deposit > cAssetBalanceInit) {
    //         deposit = cAssetBalanceInit;
    //     }

    //     liquidityProviders.supplyCErc20(address(cDAI), deposit);

    //     uint256 cAssetBalance = liquidityProviders.getCAssetBalance(address(this), address(cDAI));

    //     assert(cAssetBalance == (cAssetBalanceInit + deposit));
    //     assert(cAssetBalance == ICERC20(cDAI).balanceOf(address(liquidityProviders)));
    // }

    // function testWithdrawErc20(uint256 amount) public {
    //     IERC20 underlying = IERC20(DAI);
    //     ICERC20 cToken = ICERC20(cDAI);

    //     uint256 assetBalanceInit = underlying.balanceOf(address(this));

    //     // we have an initial balance of 10000, so we prevent the fuzzer from testing higher values.
    //     // the proper solution would be to provide a bounded fuzz via foundry
    //     if (amount > 10000 ether) {
    //         amount = 10000 ether;
    //     } else if (amount < 0.000000001 ether) {
    //         amount = 0.000000001 ether;
    //     }

    //     uint256 cAssetBalanceInit = liquidityProviders.getCAssetBalance(
    //         address(this),
    //         address(cDAI)
    //     );

    //     liquidityProviders.withdrawErc20(address(DAI), amount);

    //     (, uint256 redeemTokens) = divScalarByExpTruncate(
    //         amount,
    //         Exp({ mantissa: cToken.exchangeRateCurrent() })
    //     );

    //     uint256 assetBalance = underlying.balanceOf(address(this));

    //     uint256 cAssetBalance = liquidityProviders.getCAssetBalance(address(this), address(cDAI));

    //     assert(assetBalance == (assetBalanceInit + amount));
    //     assert(cAssetBalance == (cAssetBalanceInit - redeemTokens));
    //     assert(cAssetBalance == cToken.balanceOf(address(liquidityProviders)));
    // }

    // function testWithdrawCErc20(uint256 amount) public {
    //     uint256 cAssetBalanceInit = liquidityProviders.getCAssetBalance(
    //         address(this),
    //         address(cDAI)
    //     );

    //     // this enables us to test all values up to the deposited amount in setUp.
    //     // there should be fail case test that tries above the initial balance
    //     if (amount > cAssetBalanceInit) {
    //         amount = cAssetBalanceInit;
    //     }

    //     liquidityProviders.withdrawCErc20(address(cDAI), amount);

    //     uint256 cAssetBalance = liquidityProviders.getCAssetBalance(address(this), address(cDAI));

    //     assert(cAssetBalance == (cAssetBalanceInit - amount));
    //     assert(cAssetBalance == ICERC20(cDAI).balanceOf(address(liquidityProviders)));
    // }

    // function testSupplyEth(uint64 deposit) public {
    //     ICEther cToken = ICEther(cETH);

    //     uint256 assetBalanceInit = address(this).balance;

    //     uint256 cAssetBalanceInit = liquidityProviders.getCAssetBalance(
    //         address(this),
    //         address(cETH)
    //     );

    //     // TODO(Calculate cAsset conversion rate here)
    //     liquidityProviders.supplyEth{ value: deposit }();

    //     (, uint256 mintTokens) = divScalarByExpTruncate(
    //         deposit,
    //         Exp({ mantissa: cToken.exchangeRateCurrent() })
    //     );

    //     uint256 assetBalance = address(this).balance;

    //     uint256 cAssetBalance = liquidityProviders.getCAssetBalance(address(this), address(cETH));

    //     assert(assetBalance == (assetBalanceInit - deposit));
    //     assert(cAssetBalance == (cAssetBalanceInit + mintTokens));
    //     assert(cAssetBalance == cToken.balanceOf(address(liquidityProviders)));
    // }

    // function testWithdrawEth(uint256 amount) public {
    //     ICEther cToken = ICEther(cETH);

    //     uint256 assetBalanceInit = address(this).balance;

    //     // we have an initial balance of 10000, so we prevent the fuzzer from testing higher values.
    //     // the proper solution would be to provide a bounded fuzz via foundry
    //     if (amount > 10000 ether) {
    //         amount = 10000 ether;
    //     } else if (amount < 0.000000001 ether) {
    //         amount = 0.000000001 ether;
    //     }

    //     uint256 cAssetBalanceInit = liquidityProviders.getCAssetBalance(
    //         address(this),
    //         address(cETH)
    //     );

    //     liquidityProviders.withdrawEth(amount);

    //     (, uint256 redeemTokens) = divScalarByExpTruncate(
    //         amount,
    //         Exp({ mantissa: cToken.exchangeRateCurrent() })
    //     );

    //     uint256 assetBalance = address(this).balance;

    //     uint256 cAssetBalance = liquidityProviders.getCAssetBalance(address(this), address(cETH));

    //     assert(assetBalance == (assetBalanceInit + amount));
    //     assert(cAssetBalance == (cAssetBalanceInit - redeemTokens));
    //     assert(cAssetBalance == ICEther(cETH).balanceOf(address(liquidityProviders)));
    // }
}
