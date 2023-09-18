// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;
pragma abicoder v2;

import '../NonfungiblePositionManager.sol';

contract AlgebraMockTimeNonfungiblePositionManager is AlgebraNonfungiblePositionManager {
    uint256 time;

    constructor(
        address _factory,
        address _WNativeToken,
        address _tokenDescriptor,
        address _poolDeployer
    ) AlgebraNonfungiblePositionManager(_factory, _WNativeToken, _tokenDescriptor, _poolDeployer) {}

    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }

    function setTime(uint256 _time) external {
        time = _time;
    }
}
