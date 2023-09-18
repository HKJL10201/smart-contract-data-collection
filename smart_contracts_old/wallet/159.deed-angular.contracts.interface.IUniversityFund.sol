pragma solidity ^0.6.6;


interface IUniversityFund {
    function withdraw(uint256) external;

    function ownerFund() external view returns (address);

    function grantRoleFund(bytes32, address) external;

    function revokeRoleFund(bytes32, address) external;

    function swapDAI_ETH(uint256, uint256) external returns (uint256[] memory);

    function swapETH_DAI(uint256, uint256) external returns (uint256[] memory);

    function applyFundsCompound(uint256) external;

    function appliedDAICompound() external view returns (uint256);

    function recoverFundsCompound(uint256) external;

    function applyFundsAave(uint256) external;

    function appliedDAIAave() external view returns (uint256);

    function recoverFundsAave(uint256) external;

    function setAaveMarketCollateral(address, bool) external;

    function getCompoundLiquidityAndShortfall()
        external
        view
        returns (uint256, uint256);

    function getCompoundPriceInWEI(address) external view returns (uint256);

    function getCompoundMaxBorrowInWEI(address) external view returns (uint256);

    function compoundBorrow(address, uint256) external;

    function compoundGetBorrow(address) external view returns (uint256);

    function compoundRepayBorrow(address, address, uint256) external;

    function aaveGetBorrow(address, uint256, bool) external;

    function aaveRepayBorrow(address, uint256) external;

    function aaveSwapBorrowRateMode(address) external;

    function setAaveMarketCollateralForDAI(bool) external;

    function enterCompoundDAIMarket() external;

    function enterCompoundMarket(address) external;

    function exitCompoundDAIMarket() external;

    function exitCompoundMarket(address) external;
}
