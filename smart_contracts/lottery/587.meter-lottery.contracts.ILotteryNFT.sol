// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILotteryNFT is IERC721 {
    function newLotteryItem(
        address player,
        uint8[4] calldata _lotteryNumbers,
        uint256 _amount,
        uint256 _issueIndex
    ) external returns (uint256);

    function getClaimStatus(uint256 tokenId) external view returns (bool);

    function claimReward(uint256 tokenId) external;

    function multiClaimReward(uint256[] calldata tokenIds) external;

    function getLotteryIssueIndex(uint256 tokenId) external view returns (uint256);

    function getLotteryNumbers(uint256 tokenId) external view returns (uint8[4] memory);

    function getLotteryAmount(uint256 tokenId) external view returns (uint256);
}