// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @notice - IGovernanceModule contract is referenced from https://etherscan.io/address/0xa0446d8804611944f1b527ecd37d7dcbe442caba#code
 */
interface IGovernanceModule {
    function notifyStakeChanged(address account, uint256 newBalance) external;
    function notifyStakesChanged(address[] calldata accounts, uint256[] calldata newBalances) external;
}
