// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyPropertyNft is ERC721, IERC721Receiver, Ownable {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("PrivateProperty", "PP") {}

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI requested for non-existing token");
        return (_tokenURIs[_tokenId]);
    }

    function mint(
        address to,
        uint256 _tokenId,
        string memory _tokenURI
    ) public onlyOwner {
        _safeMint(to, _tokenId);
        _tokenURIs[_tokenId] = _tokenURI;
    }

    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
        delete _tokenURIs[_tokenId];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
