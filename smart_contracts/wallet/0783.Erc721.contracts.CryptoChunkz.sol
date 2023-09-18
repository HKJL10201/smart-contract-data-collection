//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoChunkz is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    bool public saleIsActive = false;
    enum tokenType {
        Red,
        Blue,
        Yellow,
        Green,
        Reverse,
        Wild
    }
    struct Metadata {
        address sender;
        uint256 date;
        uint256 amount;
        uint256 tokenId;
    }
    mapping(tokenType => bool) private isSaleActive;
    
    mapping(string => Metadata) public hashToMetadata;

    event Signed(string hash, address sender, uint256 date, uint256 amount);

    constructor() ERC721("CryptoChunkz", "CHEEZ_NFT") {
    }

    function flipSaleState(tokenType _tokenType) public onlyOwner {
        isSaleActive[_tokenType] = !isSaleActive[_tokenType];
    }

    function getSaleState(tokenType _tokenType) public view onlyOwner returns(bool) {
        return isSaleActive[_tokenType];
    }


    function sign(string memory hash, uint amount, uint256 tokenId) public {
        hashToMetadata[hash] = Metadata(msg.sender, block.timestamp, amount,tokenId);
        emit Signed(hash, msg.sender, block.timestamp, amount);
    }

    function verifyAndSend(string memory hash) public view returns (address sender, uint256 date) {
        Metadata memory metadata = hashToMetadata[hash];
        require(metadata.date > 0, "Invalid Signature");
        return (metadata.sender, metadata.date);
    }

    function mintItem(address account, string memory uri, tokenType _tokenType ) public returns (uint256) {
        require(isSaleActive[_tokenType], "sale is not active");
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(account, newItemId);
        _setTokenURI(newItemId, uri);

        return newItemId;
    }

    function claimReverse(address account, string memory uri, tokenType _tokenType ) public returns (uint256) {
        require(isSaleActive[_tokenType], "sale is not active");
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(account, newItemId);
        _setTokenURI(newItemId, uri);

        return newItemId;
    }

    using Strings for uint256;


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

}
