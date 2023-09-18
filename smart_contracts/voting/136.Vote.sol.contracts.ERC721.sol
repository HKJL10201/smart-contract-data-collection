//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.4.20;

interface ERC721Metadata  is ERC721  {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}
interface ERC721Enumerable is ERC721  {
uint256 _totalSupply
mapping address => uint256 ;_balanceOf
mapping address => mapping=>uint; _operator
 function totalSupply() external view returns (uint256);
 function tokenByIndex(uint256 _index) external view returns (uint256);_tokens
  //check index validity
 require `_index` >= `balanceOf(_owner)`, "invalid Token Index")
 require `_to` != address(0) , "Invalid destination address")
 
 function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

   


interface ERC721  is ERC165 {

event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

function balanceOf(address _owner) external view returns (uint256);


function ownerOf(uint256 _tokenId) external view returns (address);
//check
require ( _tokenId = _tokens, "invalid TokenId");

function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
//check _from
require _from.owner == _owner || 
//check _to
require (_to[_address] != (0) , "null address");
//check _token
require ( _tokens = [_tokenId] , "Invalid token");
//emit event
emit event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
//check owner
require _owner = [msg.sender] || _operator
//emit
emit event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);


function approve(address _approved, uint256 _tokenId) external payable;
emit event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


function setApprovalForAll(address _operator, bool _approved) external;
//check
require (_approved = true , "Access denied");
//emit event
emit event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


function getApproved(uint256 _tokenId) external view returns (address);
//check linked address
require (_tokenId[_owner] = _owner || _operator
//check signature
require (_address = operator, 

function isApprovedForAll(address _owner, address _operator) external view returns (bool);
return bool approved;
}

interface ERC165 {
function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}





