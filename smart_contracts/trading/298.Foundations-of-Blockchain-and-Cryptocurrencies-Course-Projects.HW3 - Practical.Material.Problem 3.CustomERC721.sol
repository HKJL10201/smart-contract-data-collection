pragma solidity ^0.5.1;

import "./SafeMath.sol";
import "./AddressUtils.sol";


contract ERC721Receiver {
    
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  function onERC721Received(address _from, uint256 _tokenId, bytes memory _data) public returns(bytes4);
}


contract ERC721Interface {

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function approve(address _approved, uint256 _tokenId) public;
    function setApprovalForAll(address _operator, bool _approved) public;
    function getApproved(uint256 _tokenId) public view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract ERC721 is ERC721Interface {
    
    using SafeMath for uint256;
    using AddressUtils for address;

    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    mapping (uint256 => address) internal tokenOwner;
    mapping (address => uint256) internal ownedTokensCount;
    mapping (uint256 => address) internal tokenApprovals;

    // address "A" allows address "B" to operate all A's assets
    mapping (address => mapping (address => bool)) internal operatorApprovals;


    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(tokenOwner[_tokenId] != address(0));
        return tokenOwner[_tokenId];
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        return tokenOwner[_tokenId] == _spender || getApproved(_tokenId) == _spender || isApprovedForAll(ownerOf(_tokenId), _spender);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        clearApproval(_from , _tokenId);
        removeTokenFrom(_from , _tokenId);
        addTokenTo(_to , _tokenId);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        // if target address is a contract, make sure it supports ERC721 interface
        if (!_to.isContract()) {
            transferFrom(_from, _to, _tokenId);
        }
        else {
            require(ERC721Receiver(_to).onERC721Received(_from, _tokenId, data) == ERC721_RECEIVED);
            transferFrom(_from , _to ,_tokenId);    
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from , _to , _tokenId , "");
    }

    function clearApproval(address _owner, uint256 _tokenId) internal view {
        require(ownerOf(_tokenId) == _owner);
        tokenApprovals[_tokenId] == address(0);
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }
    
    function approve(address _approved, uint256 _tokenId) public {
        require(ownerOf(_tokenId) != _approved && (msg.sender == ownerOf(_tokenId) || isApprovedForAll(ownerOf(_tokenId), msg.sender)));
        tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId) ,_approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(msg.sender != _operator);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function onERC721Received(address, uint256, bytes memory) public pure returns (bytes4) {
        return ERC721_RECEIVED;
    }
}