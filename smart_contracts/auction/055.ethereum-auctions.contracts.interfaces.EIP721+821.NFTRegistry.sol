pragma solidity ^0.4.18;

contract NFTRegistry {
    function totalSupply() public view returns (uint256 total);
    function transfer(address _to, uint256 _tokenId) public;
    function ownerOf(uint256 assetId) public view returns (address);
}