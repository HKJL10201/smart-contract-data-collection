//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IEscrow {
    function donateToBundler(address surplusRecipient) external payable;
    function cumulativeDonations() external view returns (uint256);
    function deposit(address searcherMetaTxSigner) external payable returns (uint256 newBalance);
    function nextSearcherNonce(address searcherMetaTxSigner) external view returns (uint256 nextNonce);
    function searcherEscrowBalance(address searcherMetaTxSigner) external view returns (uint256 balance);
    function searcherLastActiveBlock(address searcherMetaTxSigner) external view returns (uint256 lastBlock);
}
