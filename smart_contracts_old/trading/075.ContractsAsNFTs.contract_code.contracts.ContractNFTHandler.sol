// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./NFTContract.sol";

contract ContractNFTHandler is ERC721 {
    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        tokenCount = 1;
    }

    struct NFT {
        uint256 id;
        uint256 price;
        bool onSale;
        address contractAddress;
    }

    uint256 public tokenCount;
    mapping (address => uint256) public _tokenAddressToId;
    mapping (uint256 => address) public _tokenIdtoAdderss;    
    mapping (uint256 => uint256) public _tokenPrices;
    mapping (uint256 => bool) public _forSale;

    modifier isForSale(uint256 tokenId) {
        require(_forSale[tokenId], "Contract is not currently for sale");
        _;
    }

    modifier isOwner(uint256 tokenId) {
        require(_msgSender()==ownerOf(tokenId), "ERC721: caller is not owner");
        _;
    }

    modifier isApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is neither owner nor approved");
        _;
    }

    function _updateOwnershipInNFT(uint256 tokenId, address to) private {
        NFTContract nft = NFTContract(_tokenIdtoAdderss[tokenId]);
        nft.transferOwnership(to);
    }

    function _burn(uint256 tokenId) internal virtual override {
        _updateOwnershipInNFT(tokenId, address(0));
        delete _tokenPrices[tokenId];
        delete _forSale[tokenId];
        delete _tokenAddressToId[_tokenIdtoAdderss[tokenId]];
        delete _tokenIdtoAdderss[tokenId];
        super._burn(tokenId);
    }
    
    /**
     * @dev Mint an NFT for a smart contract that inherits from NFTContract.sol
     * Can't mint NFT for contract if caller is not owner or contract hasn't
     * set handler contract address or the NFT for that contrat's ownership has already been minted
     */
    function mintContract(address contractAddress, uint256 price) external {
        require(_tokenAddressToId[contractAddress]==0, "Contract already minted");
        NFTContract nft = NFTContract(contractAddress);
        require(nft.getOwner()==_msgSender(), "You can't mint NFT for a contract you don't own");
        require(nft.getHandlerContract()==address(this), "Handler contract address hasn't been set properly in your contract");
        _tokenAddressToId[contractAddress] = tokenCount;
        _tokenIdtoAdderss[tokenCount] = contractAddress;
        _tokenPrices[tokenCount] = price;
        _forSale[tokenCount] = false;
        _safeMint(_msgSender(), tokenCount);
        tokenCount++;
    }

    function burnContract(uint256 tokenId) external isOwner(tokenId){
        _burn(tokenId);
    }

    function setPrice(uint256 tokenId, uint256 price) external isApprovedOrOwner(tokenId) {
        _tokenPrices[tokenId] = price;
    }

    // Change the sale status of an NFT if the sale status of an NFT is false, it can no longer be pruchased using the purchaseNFT function
    function setSaleStatus(uint256 tokenId, bool saleStatus) external isApprovedOrOwner(tokenId) {
        _forSale[tokenId] = saleStatus;
    }

    // Change ownership of an NFT currently on sale
    function purchaseNFT(uint256 tokenId, address to) external payable isForSale(tokenId) {
        uint256 price = _tokenPrices[tokenId];
        require(msg.value>=price*(1 wei), "Not enough money");

        // Transfer record of ownership
        address currentOwner = ownerOf(tokenId);
        _transfer(currentOwner, to, tokenId);
        _updateOwnershipInNFT(tokenId, to);

        // Pay the original owner and refund the excess money to the buyer
        address payable owner = payable(ownerOf(tokenId));
        address payable buyer = payable(msg.sender);
        owner.transfer(price);
        buyer.transfer(msg.value-price);

        // Set sale status to false
        _forSale[tokenId] = false;
    }

    // Overriding base transfer functions to include _updateOwnershipNFT
    function transferFrom(address from, address to, uint256 tokenId) public virtual override isOwner(tokenId) {
        _transfer(from, to, tokenId);
        _updateOwnershipInNFT(tokenId, to);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override isOwner(tokenId) {
        safeTransferFrom(from, to, tokenId, "");
        _updateOwnershipInNFT(tokenId, to);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override isOwner(tokenId) {
        _safeTransfer(from, to, tokenId, _data);
        _updateOwnershipInNFT(tokenId, to);
    }

    function getAllNFTDetails() public view returns(NFT[] memory) {
        NFT[] memory nftDetails = new NFT[](tokenCount-1);
        for (uint i=1; i<tokenCount; i++) {
            nftDetails[i-1] = NFT(i, _tokenPrices[i], _forSale[i], _tokenIdtoAdderss[i]);
        }
        return nftDetails;
    }

    function getNFTDetails(uint256 tokenId) public view returns(NFT memory) {
        NFT memory nftDetails = NFT(tokenId, _tokenPrices[tokenId], _forSale[tokenId], _tokenIdtoAdderss[tokenId]);
        return nftDetails;
    }
}