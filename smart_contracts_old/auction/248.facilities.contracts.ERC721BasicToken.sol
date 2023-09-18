pragma solidity ^0.4.19;

import './ERC721.sol';
import "./helpers/SafeMath.sol";
import "./Allowance.sol";

contract ERC721BasicTokenContract is AllowanceAndOwnershipContract {
    using SafeMath for uint256;
    
    mapping (address => uint256[]) internal ownedTokens; // (ownerAddress => [tokenId, .....])
    mapping(uint256 => uint256) internal ownedTokensIndex;
    uint256[] internal allTokens;

    string internal name_;
    string internal symbol_;
    address internal tokenSaleAddress;
    
    constructor(string _name, string _symbol) public {
        name_ = _name;
        symbol_ = _symbol;
    }
    
    function name() external view returns (string) {
        return name_;
    }
    
    function symbol() external view returns (string) {
        return symbol_;
    }
    
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }
    
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < totalSupply());
        return _index;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokens[_owner].length;
    }
    
    function tokensOf(address _owner) public view returns (uint256[]) {
        require( _owner != address(0));
        return ownedTokens[_owner];
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    } 
    
    function transfer(address _to, uint256 _tokenId) 
        external
        
        onlyOwnerOf(_tokenId)
    {
        _clearApprovalAndTransfer(msg.sender, _to, _tokenId);   
    }
    
    function takeOwnership(uint256 _tokenId)
    external
    {
        require(isSenderApprovedFor(_tokenId));
        _clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }
    
    function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
     )
    public
    {
        require(isSenderApprovedFor(_tokenId));
        require(ownerOf(_tokenId) == _from);
        _clearApprovalAndTransfer(ownerOf(_tokenId), _to, _tokenId);
    }
    
    function getTokenSaleAddress () public view returns (address) {
        return tokenSaleAddress;
    }
    
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));

        _addToken(_to, _tokenId);
        emit Transfer(0x0, _to, _tokenId);
    }
    
    function _clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        require(_to != ownerOf(_tokenId));
        require(ownerOf(_tokenId) == _from);

        _clearApproval(_from, _tokenId);
        _removeToken(_from, _tokenId);
        _addToken(_to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }
    
    function _clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) ==_owner);
        tokenApprovals[_tokenId] = 0;
        emit Approval(_owner, 0, _tokenId);
    }
    
    function _addToken(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        uint256 length = balanceOf(_to);
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
        allTokens.push(_tokenId);
    }
    
    function _removeToken(address _from, uint256 _tokenId) internal {
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = balanceOf(_from).sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];
        
        tokenOwner[_tokenId] = 0;
        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
        
        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
        allTokens.push(_tokenId);
    }
}