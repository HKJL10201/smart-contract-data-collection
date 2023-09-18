// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract NftMarketplace {

  struct Nft {
    address owner;
    uint256 price;
  }

  struct NftContract {
    mapping(uint256 => Nft) nfts;
  }

  mapping(uint256 => NftContract) contracts;

  uint256 public numContracts;

  function addNftContract(uint256[2][] calldata _nfts) external {
    NftContract storage nftContract = contracts[numContracts];
    numContracts;

    for (uint256 i = 0; i < _nfts.length; i++) {
        nftContract.nfts[_nfts[i][0]] = Nft(msg.sender, _nfts[i][1]);
    }
  }

  function getPrice(uint256 _nftContractId, uint256 _nftId) external view returns (uint256 price) {
    NftContract storage nftContract = contracts[_nftContractId];
    return nftContract.nfts[_nftId].price;
  }

  function buy(
    uint256 _nftContract,
    uint256 _nftId
  ) external payable returns (bool success) {
    NftContract storage nftContract = contracts[_nftContract];
    Nft storage nft = nftContract.nfts[_nftId];
    require(msg.value >= nft.price, "insufficient funds");
    nft.owner = msg.sender;
    return true;
  }

  function getOwner(uint256 _nftContract, uint256 _nftId) external view returns (address) {
      NftContract storage nftContract = contracts[_nftContract];
      return nftContract.nfts[_nftId].owner;
  }
}