// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "hardhat/console.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

contract DutchAction is Ownable, ERC721A {

    // Import the SafeMath library
    using SafeMath for uint;

    struct tokenBetchPrice {
        uint mintPrice;
        uint total;
    }

    mapping (address => tokenBetchPrice) private allMintData;

    // Define the online status
    bool private online = true;

    // Define the revealed
    bool private revealed = true;

    // Define the baseURI
    string private baseURI;

    // Define the start time
    uint private startTimestamp = 1676372400;

    // Define the end time
    uint private endTimestamp = 1676390400;

    // Define the default price
    uint private defaultPricePerToken = 2 ether;

    // Define the decay rate
    uint private priceDecayRate = 0.05 ether;

    // Define the time interval for decay
    uint private decayInterval = 900;

    // Define the minimum price
    uint private minimumPricePerToken = 0.35 ether;

    // Define the total supply
    uint private supply = 4000;

    // Define the mint max NFTs
    uint private mintLimit = 2;

    constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol) {}

    /**
    * @dev function to Dutch Action Mint NFTs
    * @param _total total number of NFTs to Dutch Action Mint
    */
    function DutchActionMint(uint _total) public payable isNormalUser isCheckMint(_total) {
        uint currentMintPrice = getCurrentMintPrice();
        require((msg.value.mul(_total)) >= currentMintPrice, "Did not send enough ether");
        allMintData[msg.sender].mintPrice += currentMintPrice.mul(_total);
        allMintData[msg.sender].total += _total;
        for(uint i = 0; i < _total; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex + 1);
        }
    }

    /**
    * @dev function to get the current mint price of NFTs
    * @return uint current mint price
    */
    function getCurrentMintPrice() public view returns(uint) {
        uint newPrice = defaultPricePerToken;
        uint blockTime = block.timestamp;
        uint timeDifference = blockTime.sub(startTimestamp);
        uint elapsedPeriods = timeDifference.div(decayInterval);
        uint targetPrice = elapsedPeriods.mul(priceDecayRate);
        int256 diff = int256(defaultPricePerToken) - int256(targetPrice);
        int256 minPrice = int256(minimumPricePerToken);
        if (diff <= minPrice) {
            newPrice = minimumPricePerToken;
        } else {
            newPrice = defaultPricePerToken.sub(targetPrice);
        }

        return newPrice;
    }

    /**
    * @dev function to set the base URI for NFTs
    * @param _uri base URI string
    */
    function setBaseURI(string memory _uri) external  onlyOwner {
        baseURI = _uri;
    }

    /**
    * @dev modifier to check if the caller is a normal user
    */
    modifier isNormalUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    * @dev function to get the token URI for a specific token
    * @param _tokenId the token id
    * @return string memory token URI
    */
    function tokenURI(uint _tokenId) public view override returns(string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if (!revealed) return baseURI;
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    /**
    * @dev modifier to check if the conditions for minting NFTs are met
    * @param _total total number of NFTs to mint
    */
    modifier isCheckMint(uint _total) {
        require((allMintData[msg.sender].total + _total) <= mintLimit, "Can only mint max number NFTs");
        require(block.timestamp <= endTimestamp, "DutchAuction is finished!");
        require(block.timestamp >= startTimestamp, "DutchAuction has not started!");
        require(online == true, "DutchAuction is Offline");
        require(_total + totalSupply() <= supply, "Max Supply for DutchAuction reached!");
        _;
    }
    
    /**
    * @dev function to set the online status of the contract
    * @param _online true if the contract is online, false otherwise
    */
    function setOnline(bool _online) public onlyOwner {
        online = _online;
    }

    /**
    * @dev function to set the revealed status of the contract
    * @param _revealed true if the contract is revealed, false otherwise
    */
    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    /**
    * @dev function to set the start timestamp of the contract
    * @param _startTimestamp start timestamp
    */
    function setStartTimestamp(uint _startTimestamp) public onlyOwner {
        startTimestamp = _startTimestamp;
    }

    /**
    * @dev function to set the end timestamp of the contract
    * @param _endTimestamp end timestamp
    */
    function setEndTimestamp(uint _endTimestamp) public onlyOwner {
        endTimestamp = _endTimestamp;
    }

    /**
    * @dev function to set the price decay rate of the contract
    * @param _priceDecayRate price decay rate
    */
    function setPriceDecayRate(uint _priceDecayRate) public onlyOwner {
        priceDecayRate = _priceDecayRate;
    }

    /**
    * @dev function to set the decay interval of the contract
    * @param _decayInterval decay interval
    */
    function setDecayInterval(uint _decayInterval) public onlyOwner {
        decayInterval = _decayInterval;
    }
    /**
    * @dev function to set the minimum price per token of the contract
    * @param _minimumPricePerToken minimum price per token
    */
    function setMinimumPricePerToken(uint _minimumPricePerToken) public onlyOwner {
        minimumPricePerToken = _minimumPricePerToken;
    }
    /**
    * @dev function to set the total supply of the contract
    * @param _supply total supply
    */
    function setSupply(uint _supply) public onlyOwner {
        supply = _supply;
    }
    /**
    * @dev function to set the mint limit of the contract
    * @param _mintLimit mint limit
    */
    function setMintLimit(uint _mintLimit) public onlyOwner {
        mintLimit = _mintLimit;
    }
}