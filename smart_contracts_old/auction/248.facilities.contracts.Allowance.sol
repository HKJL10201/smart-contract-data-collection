pragma solidity ^0.4.19;
import "./helpers/SafeMath.sol";
import './ERC721.sol';

contract AllowanceAndOwnershipContract is ERC721 {
    using SafeMath for uint256;
    
    mapping (uint256 => address) internal tokenOwner; // (tokenId => ownerAddress)
    mapping (uint256 => address) internal tokenApprovals; // (tokenId => approvedAddress)
    mapping (address => mapping (address => bool)) internal operatorApprovals; // (ownerAddress => (approvedAddress => bool))
    
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }
    
    function getApprovedAddress(uint256 _tokenId) public view returns(address) {
        return  tokenApprovals[_tokenId];
    }
    
    function isSpecificallyApprovedFor(address _asker, uint256 _tokenId) internal view returns (bool) {
        return getApprovedAddress(_tokenId) == _asker;
    }
    
    function isApprovedForAll(address _owner, address _operator) public view returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }
    
    function isSenderApprovedFor(uint256 _tokenId) internal view returns(bool) {
        return
            ownerOf(_tokenId) == msg.sender ||
            isSpecificallyApprovedFor(msg.sender, _tokenId) ||
            isApprovedForAll(ownerOf(_tokenId), msg.sender);
    }
    
    function approve(address _to, uint256 _tokenId) external onlyOwnerOf(_tokenId)
    {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        if (getApprovedAddress(_tokenId) != 0 || _to != 0) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }
    
    function setApprovalForAll(address _to, bool _approved)
        external
    {
        if(_approved) {
            approveAll(_to);
        } else {
            disapproveAll(_to);
        }
    }
    
    function approveAll(address _to)
        public
    {
        require(_to != msg.sender);
        require(_to != address(0));
        operatorApprovals[msg.sender][_to] = true;
        emit ApprovalForAll(msg.sender, _to, true);
    }
    
    
    function disapproveAll(address _to)
    public
    {
        require(_to != msg.sender);
        delete operatorApprovals[msg.sender][_to];
        emit ApprovalForAll(msg.sender, _to, false);
    }
}