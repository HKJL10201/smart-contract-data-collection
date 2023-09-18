pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTCollection is ERC721, ERC721URIStorage, AccessControl {
    uint256 private counter;
    bytes32 public constant MINTER = keccak256("MINTER");

    constructor() ERC721("NFTCollection", "NFC") {
        _grantRole(MINTER, msg.sender);
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER) {
        uint256 id = counter;
        _safeMint(to, id);
        _setTokenURI(id, uri);
        counter++;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
