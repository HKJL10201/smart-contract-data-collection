/**
 * Composable DeFi NFT Bridge
 * Picasso Grant Application
 */
 
pragma solidity ^0.8.19;

contract NFTBridge {
    // Storage variables and mappings
    mapping(uint256 => address) private tokenOwners;
    mapping(address => uint256) private tokenBalances;
    mapping(uint256 => uint256) private timelocks;
    mapping(address => uint256) private approvalLimits;
    
    // Events
    event NFTMoved(uint256 indexed tokenId, address indexed from, address indexed to, uint256 timestamp);
    
    // Modifiers
    modifier onlyTokenOwner(uint256 tokenId) {
        require(tokenOwners[tokenId] == msg.sender, "You do not own this NFT.");
        _;
    }
    
    // Functions
    
    function moveNFT(uint256 tokenId, address to) external onlyTokenOwner(tokenId) {
        require(to != address(0), "Invalid destination address.");
        require(timelocks[tokenId] <= block.timestamp, "Timelock period not over.");
        
        address from = msg.sender;
        
        // Update token ownership
        tokenOwners[tokenId] = to;
        
        // Update token balances
        tokenBalances[from]--;
        tokenBalances[to]++;
        
        emit NFTMoved(tokenId, from, to, block.timestamp);
    }
    
    function setTimelock(uint256 tokenId, uint256 releaseTime) external onlyTokenOwner(tokenId) {
        timelocks[tokenId] = releaseTime;
    }
    
    function setApprovalLimit(uint256 limit) external {
        approvalLimits[msg.sender] = limit;
    }
    
    function getTokenOwner(uint256 tokenId) external view returns (address) {
        return tokenOwners[tokenId];
    }
    
    function getTokenBalance(address owner) external view returns (uint256) {
        return tokenBalances[owner];
    }
    
    function getApprovalLimit(address owner) external view returns (uint256) {
        return approvalLimits[owner];
    }
}
