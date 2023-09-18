// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./nf-token-metadata.sol";

/**
 * @dev This is an example contract implementation of NFToken with metadata extension.
 */
contract Cryptoducks is NFTokenMetadata {
    address owner;

    /**
     * @dev Contract constructor. Sets metadata extension `name` and `symbol`.
     */
    constructor() {
        nftName = "Cryptoducks";
        nftSymbol = "DKS";
        owner = msg.sender;
    }

    /* 
  tx.origin instead of msg.sender because i will call this contract 
  from another contract, so i want the original address of the call
  */
    modifier onlyOwner() {
        require(tx.origin == owner);
        _;
    }

    /**
     * @dev Mints a new NFT.
     * @param _to The address that will own the minted NFT.
     * @param _tokenId of the NFT to be minted by the msg.sender.
     * @param _uri String representing RFC 3986 URI.
     */
    function mint(
        address _to,
        uint256 _tokenId,
        string calldata _uri
    ) external onlyOwner {
        super._mint(_to, _tokenId);
        super._setTokenUri(_tokenId, _uri);
    }

    function transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tx.origin == _from || tx.origin == owner,
            NOT_OWNER_APPROVED_OR_OPERATOR
        );
        require(tokenOwner == _from, NOT_OWNER);
        require(_to != address(0), ZERO_ADDRESS);

        super._transfer(_to, _tokenId);
    }
}
