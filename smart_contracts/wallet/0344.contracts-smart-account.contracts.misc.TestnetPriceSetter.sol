// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./ISimplePriceOracle.sol";
import "./IChainLinkAggregator.sol";
import "../interfaces/IERC20Metadata.sol";

contract TestnetPriceSetter {
    ISimplePriceOracle public oracle;
    // tokens
    address public DAI = 0x2899a03ffDab5C90BADc5920b4f53B0884EB13cC;
    address public UNI = 0x208F73527727bcB2D9ca9bA047E3979559EB08cC;
    address public USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address public USDT = 0x79C950C7446B234a6Ad53B908fBF342b01c4d446;
    address public WBTC = 0xAAD4992D949f9214458594dF92B44165Fb84dC19;

    address public cETH = 0x64078a6189Bf45f80091c6Ff2fCEe1B15Ac8dbde;

    // chainLink
    address public BTC_ETH = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address public BTC_USD = 0xA39434A63A52E749F02807ae27335515BA4b07F7;
    address public DAI_USD = 0x0d79df66BE487753B02D015Fb622DED7f0E9798d;
    address public ETH_USD = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
    address public FORTH_USD = 0x7A65Cf6C2ACE993f09231EC1Ea7363fb29C13f2F;
    address public JPY_USD = 0x295b398c95cEB896aFA18F25d0c6431Fd17b1431;
    address public LINK_ETH = 0xb4c4a493AB6356497713A78FFA6c60FB53517c63;
    address public LINK_USD = 0x48731cF7e84dc94C5f84577882c14Be11a5B7456;
    address public USDC_USD = 0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7;
    address public XAU_USD = 0x7b219F57a8e9C7303204Af681e9fA69d17ef626f;

    constructor() {
        oracle = ISimplePriceOracle(0x65F19195e488B9C1A1Ac08ca115f197C992bC776);
    }

    function setPrices() public {
        int256 price;

        // prices have decimals privided by chainlink, compound requires 32 decimal prices (18 decimals multiplied by 1e18)
        uint256 decs = AggregatorV3Interface(BTC_USD).decimals();
        (, price, , , ) = AggregatorV3Interface(BTC_USD).latestRoundData();
        oracle.setDirectPrice(WBTC, uint256(price) * 10**(18 + 18 - IERC20Metadata(WBTC).decimals() - decs));

        decs = AggregatorV3Interface(DAI_USD).decimals();
        (, price, , , ) = AggregatorV3Interface(DAI_USD).latestRoundData();
        oracle.setDirectPrice(DAI, uint256(price) * 10**(18 + 18 - IERC20Metadata(DAI).decimals() - decs));

        decs = AggregatorV3Interface(USDC_USD).decimals();
        (, price, , , ) = AggregatorV3Interface(USDC_USD).latestRoundData();
        oracle.setDirectPrice(USDC, uint256(price) * 10**(18 + 18 - IERC20Metadata(USDC).decimals() - decs));

        decs = AggregatorV3Interface(USDC_USD).decimals();
        (, price, , , ) = AggregatorV3Interface(USDC_USD).latestRoundData();
        oracle.setDirectPrice(USDT, uint256(price) * 10**(18 + 18 - IERC20Metadata(USDT).decimals() - decs));

        decs = AggregatorV3Interface(ETH_USD).decimals();
        (, price, , , ) = AggregatorV3Interface(ETH_USD).latestRoundData();
        oracle.setUnderlyingPrice(CToken(cETH), uint256(price) * 10**(32 - decs));
    }
}
