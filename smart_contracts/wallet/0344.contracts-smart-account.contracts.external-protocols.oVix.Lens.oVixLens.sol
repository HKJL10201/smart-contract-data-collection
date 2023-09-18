// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../IOErc20.sol";
import "../IOToken.sol";
import "../PriceOracle.sol";
import "../IEIP20.sol";

// solhint-disable max-line-length

interface OVixLensInterface {
    function markets(address) external view returns (bool, bool, uint256);

    function oracle() external view returns (PriceOracle);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAssetsIn(address) external view returns (IOToken[] memory);

    function claimComp(address) external;

    function compAccrued(address) external view returns (uint256);

    function compSpeeds(address) external view returns (uint256);

    function rewardSupplySpeeds(address) external view returns (uint256);

    function rewardBorrowSpeeds(address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);
}

contract OVixLens {
    struct IOTokenMetadata {
        address cToken;
        uint256 exchangeRateCurrent;
        uint256 supplyRatePerBlock;
        uint256 borrowRatePerBlock;
        uint256 reserveFactorMantissa;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 totalSupply;
        uint256 totalCash;
        bool isListed;
        bool autoCollaterize;
        uint256 collateralFactorMantissa;
        address underlyingAssetAddress;
        uint256 cTokenDecimals;
        uint256 underlyingDecimals;
        uint256 compSupplySpeed;
        uint256 compBorrowSpeed;
        uint256 borrowCap;
    }

    function getCompSpeeds(OVixLensInterface comptroller, IOToken cToken) internal returns (uint256, uint256) {
        // Getting comp speeds is gnarly due to not every network having the
        // split comp speeds from Proposal 62 and other networks don't even
        // have comp speeds.
        uint256 compSupplySpeed = 0;
        (bool compSupplySpeedSuccess, bytes memory compSupplySpeedReturnData) = address(comptroller).call(
            abi.encodePacked(comptroller.rewardSupplySpeeds.selector, abi.encode(address(cToken)))
        );
        if (compSupplySpeedSuccess) {
            compSupplySpeed = abi.decode(compSupplySpeedReturnData, (uint256));
        }

        uint256 compBorrowSpeed = 0;
        (bool compBorrowSpeedSuccess, bytes memory compBorrowSpeedReturnData) = address(comptroller).call(
            abi.encodePacked(comptroller.rewardBorrowSpeeds.selector, abi.encode(address(cToken)))
        );
        if (compBorrowSpeedSuccess) {
            compBorrowSpeed = abi.decode(compBorrowSpeedReturnData, (uint256));
        }

        // If the split comp speeds call doesn't work, try the  oldest non-spit version.
        if (!compSupplySpeedSuccess || !compBorrowSpeedSuccess) {
            (bool compSpeedSuccess, bytes memory compSpeedReturnData) = address(comptroller).call(
                abi.encodePacked(comptroller.compSpeeds.selector, abi.encode(address(cToken)))
            );
            if (compSpeedSuccess) {
                compSupplySpeed = compBorrowSpeed = abi.decode(compSpeedReturnData, (uint256));
            }
        }
        return (compSupplySpeed, compBorrowSpeed);
    }

    function cTokenMetadata(IOToken cToken) public returns (IOTokenMetadata memory) {
        uint256 exchangeRateCurrent = cToken.exchangeRateCurrent();
        OVixLensInterface comptroller = OVixLensInterface(address(cToken.comptroller()));
        (bool isListed, bool autoCollaterize, uint256 collateralFactorMantissa) = comptroller.markets(address(cToken));
        address underlyingAssetAddress;
        uint256 underlyingDecimals;

        if (compareStrings(cToken.symbol(), "oMATIC")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            IOErc20 cErc20 = IOErc20(address(cToken));
            underlyingAssetAddress = cErc20.underlying();
            underlyingDecimals = IEIP20(cErc20.underlying()).decimals();
        }

        (uint256 compSupplySpeed, uint256 compBorrowSpeed) = getCompSpeeds(comptroller, cToken);

        uint256 borrowCap = 0;
        (bool borrowCapSuccess, bytes memory borrowCapReturnData) = address(comptroller).call(
            abi.encodePacked(comptroller.borrowCaps.selector, abi.encode(address(cToken)))
        );
        if (borrowCapSuccess) {
            borrowCap = abi.decode(borrowCapReturnData, (uint256));
        }

        return
            IOTokenMetadata({
                cToken: address(cToken),
                exchangeRateCurrent: exchangeRateCurrent,
                supplyRatePerBlock: cToken.supplyRatePerTimestamp(),
                borrowRatePerBlock: cToken.borrowRatePerTimestamp(),
                reserveFactorMantissa: cToken.reserveFactorMantissa(),
                totalBorrows: cToken.totalBorrows(),
                totalReserves: cToken.totalReserves(),
                totalSupply: cToken.totalSupply(),
                totalCash: cToken.getCash(),
                isListed: isListed,
                autoCollaterize: autoCollaterize,
                collateralFactorMantissa: collateralFactorMantissa,
                underlyingAssetAddress: underlyingAssetAddress,
                cTokenDecimals: cToken.decimals(),
                underlyingDecimals: underlyingDecimals,
                compSupplySpeed: compSupplySpeed,
                compBorrowSpeed: compBorrowSpeed,
                borrowCap: borrowCap
            });
    }

    function cTokenMetadataAll(IOToken[] calldata cTokens) external returns (IOTokenMetadata[] memory) {
        uint256 cTokenCount = cTokens.length;
        IOTokenMetadata[] memory res = new IOTokenMetadata[](cTokenCount);
        for (uint256 i = 0; i < cTokenCount; i++) {
            res[i] = cTokenMetadata(cTokens[i]);
        }
        return res;
    }

    struct IOTokenBalances {
        address cToken;
        uint256 balanceOf;
        uint256 borrowBalanceCurrent;
        uint256 balanceOfUnderlying;
        uint256 tokenBalance;
        uint256 tokenAllowance;
    }

    function cTokenBalances(IOToken cToken, address payable account) public returns (IOTokenBalances memory) {
        uint256 balanceOf = cToken.balanceOf(account);
        uint256 borrowBalanceCurrent = cToken.borrowBalanceCurrent(account);
        uint256 balanceOfUnderlying = cToken.balanceOfUnderlying(account);
        uint256 tokenBalance;
        uint256 tokenAllowance;

        if (compareStrings(cToken.symbol(), "oMATIC")) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            IOErc20 cErc20 = IOErc20(address(cToken));
            IEIP20 underlying = IEIP20(cErc20.underlying());
            tokenBalance = underlying.balanceOf(account);
            tokenAllowance = underlying.allowance(account, address(cToken));
        }

        return
            IOTokenBalances({
                cToken: address(cToken),
                balanceOf: balanceOf,
                borrowBalanceCurrent: borrowBalanceCurrent,
                balanceOfUnderlying: balanceOfUnderlying,
                tokenBalance: tokenBalance,
                tokenAllowance: tokenAllowance
            });
    }

    function cTokenBalancesAll(IOToken[] calldata cTokens, address payable account) external returns (IOTokenBalances[] memory) {
        uint256 cTokenCount = cTokens.length;
        IOTokenBalances[] memory res = new IOTokenBalances[](cTokenCount);
        for (uint256 i = 0; i < cTokenCount; i++) {
            res[i] = cTokenBalances(cTokens[i], account);
        }
        return res;
    }

    struct IOTokenUnderlyingPrice {
        address cToken;
        uint256 underlyingPrice;
    }

    function cTokenUnderlyingPrice(IOToken cToken) public view returns (IOTokenUnderlyingPrice memory) {
        OVixLensInterface comptroller = OVixLensInterface(address(cToken.comptroller()));
        PriceOracle priceOracle = comptroller.oracle();

        return IOTokenUnderlyingPrice({cToken: address(cToken), underlyingPrice: priceOracle.getUnderlyingPrice(cToken)});
    }

    function cTokenUnderlyingPriceAll(IOToken[] calldata cTokens) external view returns (IOTokenUnderlyingPrice[] memory) {
        uint256 cTokenCount = cTokens.length;
        IOTokenUnderlyingPrice[] memory res = new IOTokenUnderlyingPrice[](cTokenCount);
        for (uint256 i = 0; i < cTokenCount; i++) {
            res[i] = cTokenUnderlyingPrice(cTokens[i]);
        }
        return res;
    }

    struct AccountLimits {
        IOToken[] markets;
        uint256 liquidity;
        uint256 shortfall;
    }

    function getAccountLimits(OVixLensInterface comptroller, address account) public view returns (AccountLimits memory) {
        (uint256 errorCode, uint256 liquidity, uint256 shortfall) = comptroller.getAccountLiquidity(account);
        require(errorCode == 0);

        return AccountLimits({markets: comptroller.getAssetsIn(account), liquidity: liquidity, shortfall: shortfall});
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}
