// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBlindAuction {

    function CommitBid(uint _amount, bytes32 _salt) external;


    function RevealBid(uint _amount, bytes32 _salt) external;

    function createAuction(address _nftContract,uint _tokenId) external;

    function getWinner() external returns (address _winner);


    function claimItem() payable external;

    function withdrawFunds() external;

    function cancelAuction() external ;

    function reclaimFunds() external;
}