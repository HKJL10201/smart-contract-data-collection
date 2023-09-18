pragma solidity 0.8.7;

// Creator has many NFTs --> several NFT-IDs
// Creator can open a dutch auction for an NFT --> sets for each NFT-ID

// AUCTION

// Creator settings
// - Share of the NFT that is being sold (% revenue) --> how many of those shares are being sold?
// - Start and end time --> Auction status Enum: open/closed
// - Initial price
// - Price decrease interval & amount

// Bidder settings
// - Market buy

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error AuctionClosed();
error NftNotForSale();
error NftSold();
error NotEnoughBalance();
error UpkeepNotNeeded();

contract Auction is KeeperCompatibleInterface, Ownable {
    enum AuctionStatus {
        OPEN,
        CLOSED
    }
    AuctionStatus private status;

    address payable creator;
    address immutable nftAddress;
    address constant ETH = 0x05f52c0475Fc30eE6A320973CA463BD6e4528549;
    address constant USDC = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;

    uint256[2] availableNft;
    uint256 initialPrice;
    uint256 price;
    uint256 endAuction; //timestamp

    uint256 lastTimeStamp;
    uint256 constant INTERVAL = 60;

    event PriceUpdate(uint256 indexed _newPrice, uint256 _time);
    event AuctionClosed(uint256 _time);
    event AuctionOpened(
        uint256 indexed _newPrice,
        uint256 indexed _fromId,
        uint256 indexed _toId,
        uint256 _time
    );

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
        creator = payable(msg.sender);
        lastTimeStamp = block.timestamp;
    }

    /**
     * @notice The owner of the NFT song can create a dutch auction to get
     * sponsorship in exchange for some revenue
     * @dev This function will be reverted in the following cases:
     *  - The auction is already open
     * @dev This function will emit an event with the NFT price per unit plus
     * which NFTs are being sold
     * @param _fromId Is the first NFT ID being auctioned
     * @param _toId Is the last NFT ID being auctioned
     * @param _newPrice Sets the price per NFT from which the auction starts
     * @param _auctionDuration Sets the time elapsed until the auction closes
     * automatically (in minutes)
     */
    function newAuction(
        uint256 _fromId,
        uint256 _toId,
        uint256 _newPrice,
        uint256 _auctionDuration
    ) external onlyOwner {
        //if (status != AuctionStatus.CLOSED) revert AuctionClosed();

        availableNft = [_fromId, _toId];

        for (uint256 i = _fromId; i < _toId + 1; i++) {
            IERC721(nftAddress).approve(address(this), i);
        }

        initialPrice = _newPrice;
        price = _newPrice;
        endAuction = block.timestamp + _auctionDuration * 60;

        status = AuctionStatus.OPEN;

        emit AuctionOpened(price, _fromId, _toId, block.timestamp);
    }

    /**
     * @notice Buy an specific NFT at the current price with ETH or USDC.
     * @dev This function will be reverted in the following cases:
     *  - The auction is not open
     *  - The buyer has not enough balance
     *  - The NFT is not for sale
     *  - The NFT has been bought by another user
     * @dev This function will emit a {Transfer} event
     * @param _nftId Indicates which NFT you want to buy
     * @param _token Sets with what token you will be buying
     */
    function buyNft(uint256 _nftId, address _token) public {
        //if (status != AuctionStatus.OPEN) revert AuctionClosed();
        if (_nftId < availableNft[0] || _nftId > availableNft[1])
            revert NftNotForSale();
        if (IERC20(_token).balanceOf(msg.sender) < price)
            revert NotEnoughBalance();
        IERC20(_token).approve(address(this), price);
        IERC20(_token).transferFrom(msg.sender, creator, price);
        IERC721(nftAddress).safeTransferFrom(creator, msg.sender, _nftId);
    }

    /**
     * @notice Close the auction
     * @dev The function emits the block timestamp at which the auction was closed
     */
    function closeAuction() public onlyOwner {
        //if (status != AuctionStatus.OPEN) revert AuctionClosed();
        status = AuctionStatus.CLOSED;
        emit AuctionClosed(block.timestamp);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = ((block.timestamp - lastTimeStamp) > INTERVAL);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert UpkeepNotNeeded();
        }
        price = (initialPrice * 999) / 1000;
        lastTimeStamp = block.timestamp;
    }

    function getPrice
}
