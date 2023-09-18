// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LotteryGame is ERC721 {
    address minter;

    mapping(uint256 => string) private token_contents; //mapping between a tokenId and its content

    constructor() ERC721("LotteryGame", "LOTTERY_GAME") {
        minter = msg.sender;
    }

    //Function that mint a new NFT with a given id and a content and assign it to a given address (lottery operator)
    function mint(
        address to,
        uint256 tokenId,
        string memory content
    ) public virtual {
        require(to == minter, "ERC721: must have minter role to mint");
        _mint(to, tokenId);
        setTokenContent(tokenId, content);
    }

    //Function that transfer a token from an owner to an other user (e.g. if a user wins the lottery receives a prize)
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(from, tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    //Function that return the content of a given token
    function getTokenContent(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: token does not exist!");

        return token_contents[tokenId];
    }

    event TokenContent(string content);

    //Function that set the content for a given token
    function setTokenContent(uint256 tokenId, string memory content) internal {
        require(_exists(tokenId), "ERC721: token does not exist!");
        token_contents[tokenId] = content;
        string memory str = string(
            abi.encodePacked("Set Content of Token ", Strings.toString(tokenId))
        );
        emit TokenContent(str);
    }
}
