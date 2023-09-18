// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PolimiNFT is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint public constant MAX_TOKENS = 10;
    uint public PRICE = 10000000;
    bool public isSaleActive; 
    string public baseUri;
    string public baseExtension = ".json";
    
    constructor() ERC721("Osservatori Digital Innovation NFT", "ODI") {
        baseUri = "https://bafybeidel25ngnnkraq3fzl5s75whpedfvbtocl6f4q3xj26wdidoa5jaq.ipfs.nftstorage.link/";
        }

    function mint() external payable {
        uint256 tokenId = _tokenIdCounter.current();
        require(isSaleActive, "NFTs sale not open yet");
        require(tokenId <= MAX_TOKENS, "All NFTs already minted");
        require(PRICE == msg.value, "Not enough Eth to pay for minting");
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function changeSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }    

    function withdrawAll(address payable _to) external payable onlyOwner {
        uint256 balance = address(this).balance;
        (bool myTransfer,) = _to.call{value: balance}("");
        require(myTransfer, "Failed funds transfer");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query to non-existent token");
 
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
            : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

}