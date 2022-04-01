//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface NftMarketplaceInt {
  function getPrice(uint256 nftContract, uint256 nftId) external returns (uint256 price);
  function buy(uint256 nftContract, uint256 nftId) external payable returns (bool success);
  function addNftContract(uint256 nftContract_, uint256[2][] calldata nfts_) external;
}

contract Proposal {
  address marketplaceAddr;

  constructor(address _marketplaceAddr) {
    marketplaceAddr = _marketplaceAddr;
  }

  function buyNft(uint256 _nftContractId, uint256 _nftId) external payable {
    uint256 price = NftMarketplaceInt(marketplaceAddr).getPrice(_nftContractId, _nftId);
    if (price >= msg.value) {
      bool success = NftMarketplaceInt(marketplaceAddr).buy{ value: price }(_nftContractId, _nftId);
      require(success, "purchase failed");
    } else {
      revert("insufficient value");
    }
  }
}
