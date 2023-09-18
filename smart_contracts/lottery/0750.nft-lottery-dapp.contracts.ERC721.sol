// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract ERC721 {
  function balanceOf(address _owner) external virtual view returns (uint256) ;
  function ownerOf(uint256 _tokenId) external virtual view returns (address);
  function transferFrom(address _from, address _to, uint256 _tokenId) external virtual payable;
  function approve(address _approved, uint256 _tokenId) external virtual payable;
  function getApproved(uint256 _tokenId) external virtual view returns (address);
  function setApprovalForAll(address _operator, bool _approved) external virtual;
  function isApprovedForAll(address _owner, address _operator) external view virtual returns (bool);

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
}
