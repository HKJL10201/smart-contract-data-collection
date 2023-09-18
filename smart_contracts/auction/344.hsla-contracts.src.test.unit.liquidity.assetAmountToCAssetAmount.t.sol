pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20Upgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/liquidity/ILiquidityEvents.sol";
import "../../../interfaces/compound/ICERC20.sol";

contract TestAssetAmountToCAssetAmount is Test, ILiquidityEvents, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function testAssetAmountToCAssetAmount() public {
        if (!integration) {
            cDAIToken.setExchangeRateCurrent(220154645140434444389595003); // recent exchange rate of DAI

            uint256 result = liquidity.assetAmountToCAssetAmount(address(daiToken), 1e18); // supply 1 mockCDAI, would be better to call this mock DAI as DAI has 6 decimals

            assertEq(result, 4542261642);
        } else {
            uint256 amtUsdc = daiToken.balanceOf(lender1);

            uint256 result = liquidity.assetAmountToCAssetAmount(address(daiToken), amtUsdc);

            uint256 exchangeRateCurrent = ICERC20(address(cDAIToken)).exchangeRateCurrent();

            uint256 cTokenAmount = (amtUsdc * (10**18)) / exchangeRateCurrent;

            assertEq(result, cTokenAmount);

            // This mints the same amount of cDAI directly
            // i.e., just interacting with Compound and not via NiftyApes
            // to double check the above math
            vm.startPrank(lender1);
            ICERC20(address(daiToken)).approve(address(cDAIToken), amtUsdc);
            ICERC20(address(cDAIToken)).mint(amtUsdc);
            assertEq(cDAIToken.balanceOf(lender1), result);
            vm.stopPrank();
        }
    }
}
