// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract newNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public manager;
    string[8] public tknURIs = [
        "https://ipfs.io/ipfs/QmQEuBDnjR7oGUBGhYX2k4jhoWSnCDVXUDrwebcFVAV9Eg?filename=Raspberry.jpg",
        "https://ipfs.io/ipfs/Qma44ew9c9HFfytQfAdk86jRUT7ZUQezLAZBni6riWiYuZ?filename=Strawberry.jpg",
        "https://ipfs.io/ipfs/QmT6hzsD7PJVjvDHoWNjYpqj6jjwqpq6EWj69vNTtWrYgs?filename=Grape.jpg",
        "https://ipfs.io/ipfs/Qmeq3dcCc6eVcjFUt9rH1JR1djSbpkeEBNQGsAQqxevayx?filename=Banana.png",
        "https://ipfs.io/ipfs/QmSaq7DsdUui7GHyjVz7CjKhtHHFEUVrsXpC7qWTmGQw21?filename=Pear.jpg",
        "https://ipfs.io/ipfs/QmdjirE3bzBfv8ZYowde4eUTx2rCwGFpnE9EWx9qbaYqGj?filename=Apple.jpg",
        "https://ipfs.io/ipfs/QmYUB6634bt9YXnpCizMQZGMNoHTUXZwNCHrDuXbqFBrsa?filename=Watermelon.jpg",
        "https://ipfs.io/ipfs/QmPCDeN6Y2TX7CmNqiuVoUPrnHKuJC66t8zHYFJLmeTEtb?filename=Melon.jpg"
    ];

    constructor() ERC721("newNFT", "ITM") {
        manager = msg.sender;
    }

    function awardItem(uint index) //mint a new NFT given an index. the index mean
        public
        returns (uint256)
    {
        require(index >= 0 && index <= 7);
        require(msg.sender == manager, "Only the lottery manager can mint new NFTs.");
        uint256 newItemId = _tokenIds.current();
        _mint(manager, newItemId);
        _setTokenURI(newItemId, tknURIs[index]);

        _tokenIds.increment();
        return newItemId;
    }

    function rewardWinner(address winner, uint256 tokenId) 
        public
        payable 
        returns (bool success)
    {
        require(winner != msg.sender && msg.sender == manager, "Lottery manager can't play the lottery.");
        safeTransferFrom(manager, winner, tokenId);
        return true;
    }
}
