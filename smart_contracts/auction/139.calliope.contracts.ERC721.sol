pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./AuctionFactory.sol";

contract Nft is ERC721 {
    constructor() ERC721("song", "NFT") {
        for (uint256 i; i < 10; i++) _safeMint(msg.sender, i);
    }
}
