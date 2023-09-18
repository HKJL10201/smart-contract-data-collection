// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IComptroller.sol";
import "./IInterestRateModel.sol";
import "./IEIP20NonStandard.sol";
import "./IEIP20.sol";

interface IOToken is IEIP20 {
    /**
     * @notice Indicator that this is a OToken contract (for inspection)
     */
    function isOToken() external view returns (bool);

    function accrualBlockTimestamp() external returns (uint256);

    /*** User Interface ***/
    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerTimestamp() external view returns (uint256);

    function supplyRatePerTimestamp() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function totalReserves() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function totalBorrows() external view returns (uint256);

    function comptroller() external view returns (IComptroller);

    function borrowIndex() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel) external returns (uint256);

    function _setProtocolSeizeShare(uint256 newProtocolSeizeShareMantissa) external returns (uint256);
}
