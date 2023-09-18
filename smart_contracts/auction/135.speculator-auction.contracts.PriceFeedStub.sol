//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./IERC20Mintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// For demo purpose only
contract PriceFeedStub {
    // Price feed Stub. Calculates the amount of Rand token per wei.
    // 1 ETH -> 10 Rand
    function ethToRand(uint256 weis) public pure returns (uint256) {
        return weis * 10; // todo: use safeMath
    }
}
