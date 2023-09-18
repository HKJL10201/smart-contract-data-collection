// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lotto NFT contract
 */
contract LotteryNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct LotteryInfo {
        uint8[4] numbers;
        uint256 amount;
        uint256 issueIndex;
        bool claimInfo;
        address owner;
    }

    /// @dev administrator address
    address public adminAddress;
    /// @dev TokenID => lottery information
    mapping(uint256 => uint8[4]) public lotteryInfo;
    /// @dev TokenID => lottery ticket price
    mapping(uint256 => uint256) public lotteryAmount;
    /// @dev TokenID => release index
    mapping(uint256 => uint256) public issueIndex;
    /// @dev TokenID => Whether to accept the award
    mapping(uint256 => bool) public claimInfo;

    /**
     * @dev constructor
     * @param name 名称 "Go Lottery GOC Ticket"
     * @param symbol symbol "cGLT"
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        adminAddress =  _msgSender ();
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin () {
        require(adminAddress == _msgSender(), "Admin: caller is not the admin");
        _;
    }

    /**
     * @dev Create a new Item
     * @param player user address
     * @param _lotteryNumbers lottery numbers
     * @param _amount purchase amount
     * @param _issueIndex release index
     */
    function newLotteryItem(
        address player,
        uint8[4] memory _lotteryNumbers,
        uint256 _amount,
        uint256 _issueIndex
    ) public onlyAdmin returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        lotteryInfo[newItemId] = _lotteryNumbers;
        lotteryAmount[newItemId] = _amount;
        issueIndex[newItemId] = _issueIndex;
        // _setTokenURI (newItemId, tokenURI);

        return newItemId;
    }

    /**
     * @dev Get all Token data
     * @param tokenId tokenId
     */
    function lotteryURI(uint256 tokenId) external view returns (LotteryInfo memory _lotteryInfo) {
        _lotteryInfo.numbers = lotteryInfo[tokenId];
        _lotteryInfo.amount = lotteryAmount[tokenId];
        _lotteryInfo.issueIndex = issueIndex[tokenId];
        _lotteryInfo.claimInfo = claimInfo[tokenId];
        _lotteryInfo.owner = ownerOf(tokenId);
    }

    /**
     * @dev Get lotto number
     * @param tokenId tokenId
     */
    function getLotteryNumbers(uint256 tokenId) external view returns (uint8[4] memory) {
        return lotteryInfo[tokenId];
    }

    /**
     * @dev Get the purchase amount
     * @param tokenId tokenId
     */
    function getLotteryAmount(uint256 tokenId) external view returns (uint256) {
        return lotteryAmount[tokenId];
    }

    /**
     * @dev Get release index
     * @param tokenId tokenId
     */
    function getLotteryIssueIndex(uint256 tokenId) external view returns (uint256) {
        return issueIndex[tokenId];
    }

    /**
     * @dev accept the award
     * @param tokenId tokenId
     */
    function claimReward(uint256 tokenId) external onlyAdmin {
        claimInfo[tokenId] = true;
    }

    /**
     * @dev Collect in batches
     * @param tokenIds tokenId number set
     */
    function multiClaimReward(uint256[] memory tokenIds) external onlyAdmin {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claimInfo[tokenIds[i]] = true;
        }
    }

    /**
     * @dev destroy token
     * @param tokenId tokenId
     */
    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    /**
     * @dev Get award status
     * @param tokenId tokenId
     */
    function getClaimStatus(uint256 tokenId) external view returns (bool) {
        return claimInfo[tokenId];
    }

    /**
     * @dev Update the administrator address through the previous developer
     * @param _adminAddress administrator address
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        adminAddress = _adminAddress;
    }

    /**
     * @dev set TokenURI
     * @param tokenId tokenId
     * @param _tokenURI TokenURI Land Site
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(msg.sender == adminAddress, "admin: wut?");
       // _setTokenURI (tokenId, _tokenURI);
    }

    /**
     * @dev set BaseURI
     * @param baseURI_ BaseURI 地址
     */
    function setBaseURI(string memory baseURI_) external {
        require(msg.sender == adminAddress, "admin: wut?");
       // _setBaseURI (baseURI_);
    }
}