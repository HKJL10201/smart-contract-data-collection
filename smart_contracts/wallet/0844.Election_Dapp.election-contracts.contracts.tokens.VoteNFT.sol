// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


/**
 * Counter counts the tokenId of nft, first minted nft is 0, second is 1, ...
 * In giveVoterStatus, we firstly get the tokenId of the current nft to be minted,
 *  then we mint it, then we give it a token uri, and finally
 *  we increment the counter for the next nft that might be minted
 * **/

contract VoteNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("VoteNFT", "VOTE") {}

    // this function mints an nft to the 'to' address
    // and gives it an voter status
    function giveVoterStatus(address to, string memory uri) external {
        uint256 newId = _tokenIds.current();
        _safeMint(to, newId);
        _setTokenURI(newId, uri);
        _tokenIds.increment();
    }

    // The following functions are overrides required by Solidity.

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
}
