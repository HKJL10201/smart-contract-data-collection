//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract NftMarketplace {
    // NFT ID => Purchased. set to purchased when bought
    mapping(uint256 => bool) public purchasedNFTs;

    // function buy(address nftContract, uint256 nftId)
    function buy(uint256 nftId) external payable {
        purchasedNFTs[nftId] = true;
    }
}
