// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;
pragma abicoder v2;

import '../libraries/NFTDescriptor.sol';
import '../libraries/NFTSVG.sol';
import '../libraries/HexStrings.sol';

contract NFTDescriptorTest {
    using HexStrings for uint256;

    function constructTokenURI(AlgebraNFTDescriptor.ConstructTokenURIParams calldata params)
        public
        pure
        returns (string memory)
    {
        return AlgebraNFTDescriptor.constructTokenURI(params);
    }

    function getGasCostOfConstructTokenURI(AlgebraNFTDescriptor.ConstructTokenURIParams calldata params)
        public
        view
        returns (uint256)
    {
        uint256 gasBefore = gasleft();
        AlgebraNFTDescriptor.constructTokenURI(params);
        return gasBefore - gasleft();
    }

    function tickToDecimalString(
        int24 tick,
        int24 tickSpacing,
        uint8 token0Decimals,
        uint8 token1Decimals,
        bool flipRatio
    ) public pure returns (string memory) {
        return AlgebraNFTDescriptor.tickToDecimalString(tick, tickSpacing, token0Decimals, token1Decimals, flipRatio);
    }

    function fixedPointToDecimalString(
        uint160 sqrtRatioX96,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public pure returns (string memory) {
        return AlgebraNFTDescriptor.fixedPointToDecimalString(sqrtRatioX96, token0Decimals, token1Decimals);
    }

    function feeToPercentString(uint24 fee) public pure returns (string memory) {
        return AlgebraNFTDescriptor.feeToPercentString(fee);
    }

    function addressToString(address _address) public pure returns (string memory) {
        return AlgebraNFTDescriptor.addressToString(_address);
    }

    function generateSVGImage(AlgebraNFTDescriptor.ConstructTokenURIParams memory params) public pure returns (string memory) {
        return AlgebraNFTDescriptor.generateSVGImage(params);
    }

    function tokenToColorHex(address token, uint256 offset) public pure returns (string memory) {
        return AlgebraNFTDescriptor.tokenToColorHex(uint256(uint160(token)), offset);
    }

    function sliceTokenHex(address token, uint256 offset) public pure returns (uint256) {
        return AlgebraNFTDescriptor.sliceTokenHex(uint256(uint160(token)), offset);
    }

    function rangeLocation(int24 tickLower, int24 tickUpper) public pure returns (string memory, string memory) {
        return NFTSVG.rangeLocation(tickLower, tickUpper);
    }

    function isRare(uint256 tokenId, address poolAddress) public pure returns (bool) {
        return NFTSVG.isRare(tokenId, poolAddress);
    }
}
