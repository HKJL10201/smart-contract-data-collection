pragma solidity ^0.4.18;

interface IAssetRegistry {
  function name() public view returns (string);
  function symbol() public view returns (string);
  function description() public view returns (string);
  function totalSupply() public view returns (uint256);

  function exists(uint256 assetId) public view returns (bool);
  function ownerOf(uint256 assetId) public view returns (address);
  function ownerHolderOf(uint256 assetId) public view returns (address);
  function assetData(uint256 assetId) public view returns (string);
  function safeAssetData(uint256 assetId) public view returns (string);

  function assetCount(address holder) public view returns (uint256);
  function assetByIndex(address holder, uint256 index) public view returns (uint256);
  function assetsOf(address holder) external view returns (uint256[]);
  function isOperatorAuthorizedFor(address operator, address assetHolder)
    public view returns (bool);

  function transfer(address to, uint256 assetId, bytes userData, bytes operatorData) public;
  function transfer(address to, uint256 assetId, bytes userData) public;
  function transfer(address to, uint256 assetId) public;

  function authorizeOperator(address operator, bool authorized) public;
}