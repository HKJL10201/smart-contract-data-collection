// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title feeCalculator
 * @author javadyakuza
 * @notice this library is used to calculate the block trading fees
 */
library feeCalculator {
    using Math for uint256;

    function onePercentreducer(
        uint256 wholePrice
    ) internal pure returns (uint256 _99percent) {
        return Math.mulDiv(wholePrice, 99, 100);
    }
}
