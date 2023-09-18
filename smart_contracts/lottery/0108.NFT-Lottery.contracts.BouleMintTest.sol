// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * Made by the Boule.io team.
 *
 *
 *
 * FOR DEVS USING THIS CONTRACT:
 * - Replace all VRF-related parameters (keyHash, fee, etc..) with your own (https://vrf.chain.link/)
 * - Set the TOKEN_CAP, COMMUNITY_TOKEN_CAP, and WINNER_TAKE_HOME_PERCENTAGE to whatever you see fit
 * - The tokenURI and winningURI parameters in the constructor should link to IFPS metadata files
 * - Enjoy!
 */

contract BouleMintTest is ERC721URIStorage, Ownable, VRFConsumerBase {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds; // iterator for token ids
    Counters.Counter private _communityTokenCount; // iterator for vouchers given
    Counters.Counter private _uniqueMintersCount; // iterator for unique accounts that have minted tokens

    uint256 TOKEN_CAP = 10; // maximum tokens to be sold
    uint256 COMMUNITY_TOKEN_CAP = 4; // maximum tokens that can be given to the community
    uint256 MAX_TOKEN_PURCHASE_SIZE = 100; // maximum tokens that can be given to the community
    uint256 TOKEN_PRICE = 1000000000000000000; // maximum tokens that can be given to the community
    uint256 WINNER_TAKE_HOME_PERCENTAGE = 95; // the percentage of the pot the winner gets (should be 0-100)
    mapping(address => uint256[]) tokenMapping; // an index mapping of each token owner address to its tokens
    mapping(address => bool) uniqueMinterMapping; // a boolean mapping of each unique minter

    uint256 public winningTokenId; // winning token

    bytes32 keyHash; // key hash for VRF call
    uint256 internal fee;

    string private coinTokenURI;
    string private winningTokenURI;

    /**
     * @dev NFTLottery extends the ERC721 & VRFConsumerBase contracts
     */
    constructor(string memory tokenURI, string memory winningURI)
        Ownable()
        ERC721("Boule", "BOULE")
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
        )
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10**18; // Polygon Fee (Varies by network)
        coinTokenURI = tokenURI;
        winningTokenURI = winningURI;
    }

    /**
     * @dev Verifies that the tokens are not sold out, or that the current order
     * would exceed the available token count.
     */
    modifier tokensAreNotSoldOut(uint256 tokenQuantity) {
        uint256 tokenCount = _tokenIds.current();
        require(tokenCount < TOKEN_CAP, "Tokens are sold out.");
        require(
            tokenCount + tokenQuantity <= TOKEN_CAP,
            "This many tokens do not remain."
        );
        _;
    }

    /**
     * @dev Verifies that the community tokens have not all been distributed, or that the current order
     * would exceed the available community token count.
     */
    modifier communityTokensStillRemain(uint256 tokenQuantity) {
        uint256 tokenCount = _communityTokenCount.current();
        require(
            tokenCount < COMMUNITY_TOKEN_CAP,
            "Community tokens have already been distributed."
        );
        require(
            tokenCount + tokenQuantity <= COMMUNITY_TOKEN_CAP,
            "This many community tokens do not remain."
        );
        _;
    }

    /**
     * @dev Verifies that the buyer is not purchasing too many tokens at once.
     */
    modifier tokenQuantityIsValid(uint256 tokenQuantity) {
        require(
            tokenQuantity <= MAX_TOKEN_PURCHASE_SIZE,
            "Tokens are sold out."
        );
        _;
    }

    /**
     * @dev Mints a sepcified number of tokens for the user. A fee is collected and tokens are minted.
     * @param tokenQuantity the number of tokens to be purchased
     */
    function mintToken(uint256 tokenQuantity)
        public
        payable
        tokensAreNotSoldOut(tokenQuantity)
        tokenQuantityIsValid(tokenQuantity)
    {
        require(
            msg.value >= TOKEN_PRICE * tokenQuantity,
            "Insufficient funds."
        );

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();

            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, coinTokenURI);

            tokenMapping[msg.sender].push(newItemId);
        }

        if (!uniqueMinterMapping[msg.sender]) {
            uniqueMinterMapping[msg.sender] = true;
            _uniqueMintersCount.increment();
        }
    }

    /**
     * @dev Mints tokens as a community grant to an address
     * @param recipient the recipient address of the token mint
     * @param tokenURI the uri of metadata to be attached to the nft (user is free to customize this)
     * @param tokenQuantity the number of tokens to be purchased
     */
    function mintTokensForCommunityMember(
        address recipient,
        string memory tokenURI,
        uint256 tokenQuantity
    )
        public
        onlyOwner
        tokensAreNotSoldOut(tokenQuantity)
        communityTokensStillRemain(tokenQuantity)
        tokenQuantityIsValid(tokenQuantity)
    {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _tokenIds.increment();
            _communityTokenCount.increment();
            uint256 newItemId = _tokenIds.current();

            _mint(recipient, newItemId);
            _setTokenURI(newItemId, tokenURI);

            tokenMapping[recipient].push(newItemId);
        }
    }

    /**
     * @dev Mints tokens as a community grant to a set of addresses, each receiving one token
     * @param recipients the recipient addresses of the token mint
     * @param tokenURI the uri of metadata to be attached to the nft (user is free to customize this)
     */
    function mintTokenForCommunityMembers(
        address[] memory recipients,
        string memory tokenURI
    )
        public
        onlyOwner
        tokensAreNotSoldOut(recipients.length)
        communityTokensStillRemain(recipients.length)
        tokenQuantityIsValid(recipients.length)
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            _tokenIds.increment();
            _communityTokenCount.increment();
            uint256 newItemId = _tokenIds.current();

            _mint(recipients[i], newItemId);
            _setTokenURI(newItemId, tokenURI);

            tokenMapping[recipients[i]].push(newItemId);
        }
    }

    /**
     * @dev Gets the owner of a token.
     * @param tokenId the id of the token
     * @return the owning address of a token
     */
    function getHolderForTokenId(uint256 tokenId)
        public
        view
        returns (address)
    {
        return ownerOf(tokenId);
    }

    /**
     * @dev Gets the tokens an address owns.
     * @param adr the address of the token holder
     * @return tokens an address owns
     */
    function getTokensForAddress(address adr)
        public
        view
        returns (uint256[] memory)
    {
        return tokenMapping[adr];
    }

    /**
     * @dev Gets the total number of tokens sold.
     * @return total tokens sold
     */
    function getTotalTokensSold() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Gets the total number of unique addresses that have purchased tokens.
     * @return total unique addresses
     */
    function getTotalUniqueMinters() public view returns (uint256) {
        return _uniqueMintersCount.current();
    }

    /**
     * @dev Gets the total pool size of the contract.
     * @return balance of the contract
     */
    function getPoolSize() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the remaining tokens.
     * @return remaining tokens
     */
    function getRemainingTokens() public view returns (uint256) {
        return TOKEN_CAP - _tokenIds.current();
    }

    /**
     * @dev Get random number from chainlink to assign as the winning token id.
     * @return the id of the chainlink vrf request
     */
    function generateWinningToken() public onlyOwner returns (bytes32) {
        require(winningTokenId == 0, "Winning token id has already been set.");
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        winningTokenId = (randomness % _tokenIds.current()) + 1;
    }

    /**
     * @dev Gets the winning token id.
     * @return the winning token id
     */
    function getWinningTokenId() public view returns (uint256) {
        return winningTokenId;
    }

    /**
     * @dev Gets the owner of the winning token.
     * @return the address that owns the winning token
     */
    function getWinningAddress() public view returns (address) {
        return ownerOf(winningTokenId);
    }

    /**
     * @dev Pays out the winner, then self destructs the contract,
     * sending the rest of the contract balance to the contract owner.
     */
    function cashOutWinnings() public onlyOwner {
        require(
            winningTokenId != 0,
            "There has not been a winning token declared."
        );

        address payable winningAddress = payable(getWinningAddress());

        uint256 currentBalance = address(this).balance;
        uint256 winnerPayout = (currentBalance * WINNER_TAKE_HOME_PERCENTAGE) /
            100;

        (bool sent, ) = winningAddress.call{value: winnerPayout}("");
        require(sent, "Failed to send Ether.");

        _mint(msg.sender, 0);
        _setTokenURI(0, winningTokenURI);

        uint256 remainingBalance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: remainingBalance}("");
        require(success, "Failed to send Ether.");
    }
}
