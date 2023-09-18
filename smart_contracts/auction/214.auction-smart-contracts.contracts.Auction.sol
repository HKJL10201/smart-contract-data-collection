// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import './AuctionERC20.sol';

/**
 * @title Auction
 * @author ggulaman
 * @notice Auction Smart Contract (SC). The auction last a certain amount of time, while the bidders can place their bids.
 * @notice Once the time is over, bidders can claim their ERC20 tokens if their bid is between the higher ones.
 * @dev TODO: 1. Implement a deposit fee when placing a bid, which bidder can claim after the bid is over |
 * @dev TODO: 2. Investigate if there is a more effecient way of checking if bidder has claimed their bids, than using hashBidderClaimed
 * @dev TODO: 3. CORNER CASE: If the Lowest Winner Bid Price has more than 1 bid, user will not be able to claim that amount for now. This can be handle with timestamp in the struct, so the first placed could claim
 * @dev TODO: 4. Import the OpenZeppelin Owner SC | 5. OpenZeppelin maths | 6. Check Licences
 * @dev TODO: 7. Consider to destroy SC once they are completed | 8. Add OpenZeppelin Upgrade
 */
contract Auction {
    // EVENTS
    event UserPlacedBid(address indexed user, uint256 indexed price, uint256 indexed amount); // Raised when a New Bid is Placed
    event UserRefund(address indexed user, bytes indexed receipt); // Raised when User receives their previosuly staked ETH amount
    event AuctionClaimed(address indexed claimer, address indexed winner); // Raised when the Winner or the Owner Want to Wrap up the action
    event ERC20Sent(address indexed _from, address indexed _destAddr, uint indexed _amount); // Raised when ERC20 tokens are sent
    event ETHSentToOwner(address indexed _destAddr, uint256 indexed _amount); // Raised when ETH sent to owner

    // SC VARIABLES
    AuctionERC20 erc20;
    address private auctionOwner; // address of the Auction Owner
    uint256 private auctionDeadline; // epoch time when the auction finishes
    uint256 private totalSupply; // total supply amount of the ERC20

    struct bidStruct {
        uint256 time;
        address bidder;
        uint256 price;
        uint256 amount;
    }
    bidStruct[] public listOfBids; // list of bidStruct, containing all the bid details
    uint256[] public listOfPrices; // list containing all the prices (unique). It will be used to sort all the prices.
    mapping(uint256 => uint256) public hashPriceTokens;  // hashmap where the key is the price and the value is the total staked at that price by all the users
    mapping(uint256 => uint256[]) public hashPriceReceipts;  // hashmap where the key is the price and the value is an array with all the bid receipts at that price
    mapping(address => uint256[]) public hashBidderReceipts;  // hashmap where the key is the bidder address and the value is an array with all bid receipts of the bidder
    mapping(address => bool) public hashBidderClaimed;  // hashmap where the key is the bidder address and the value is true if they have claim their bids

    /**
     * @param _owner the owner of the auction, _auctionDuration the time the auction last in seconds, _ERC20Name the name of the token, _ERC20Symbol the simbol of the token, _supply the total supply of the ERC20
     * @dev Constructor that creates the ERC20 token and sends all the suply to this SC
     */
    constructor (address _owner, uint256 _auctionDuration, string memory _ERC20Name, string memory _ERC20Symbol, uint256 _supply) {
        auctionOwner = _owner;
        auctionDeadline = _auctionDuration + block.timestamp;
        totalSupply = _supply;
        erc20 = new AuctionERC20(_ERC20Name, _ERC20Symbol, _supply, address(this));
    }

    /**
     * @notice Returns the address of the ERC20 Token
     * @return the address of the erc20 ERC20 SC
     */
    function getERC20address() public view returns (address) {
        return address(erc20);
    }

    /**
     * @notice Returns the Auction Owner for now
     * @return auctionOwner
     */
    function getAuctionOwner() public view returns (address) {
        return auctionOwner;
    }

    /**
     * @notice Returns deadline in epoch time
     * @return auctionDeadline
     */
    function getAuctionDeadline() public view returns (uint256) {
        return auctionDeadline;
    }

    /**
     * @notice Returns if the Auction is still open
     * @return True if auction deadline is greater than the current block timestamp
     */
    function getIfAuctionIsActive() public view returns (bool) {
        return auctionDeadline > block.timestamp;
    }


    /**
     * @notice quickSort algorithm implementation sorting by desc
     * @param arr the array to sort, left the lower, right the greater
     */
    function quickSort(uint[] memory arr, int left, int right) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] > pivot) i++;
            while (pivot > arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    /**
     * @notice Returns a list sorted desc;
     * @param data the array to sort
     * @return an array desc. sorted
     */
    function sort(uint[] memory data) public pure returns(uint [] memory) {
       quickSort(data, int(0), int(data.length - 1));
       return data;
    }

    /**
     * @notice Returns the list of prices offered sorted desc;
     * @return the listOfPrices array ordered desc.
     */
    function getListOfPricesSorted() public view returns(uint [] memory) {
       return sort(listOfPrices);
    }

    function getCurrentMinPrice() public view returns(uint256) {
        uint256[] memory listOfPricesSorted = getListOfPricesSorted();

        int256 totalSupplyLeft = int(totalSupply);
        uint256 minCurrentPrice;

        for (uint i=0; i < listOfPricesSorted.length; i++) {

            totalSupplyLeft -= int(hashPriceTokens[listOfPricesSorted[i]]);

            if (totalSupplyLeft <= 0) {
                minCurrentPrice = listOfPricesSorted[i];
                break;
            }

        }
        return minCurrentPrice;
    }

    /**
     * @notice Function to place a bid with ETH
     * @param _priceInWei the price per Token offered by bidder, _amountOfERC20 the amount of tokens at given price
     * @dev TODO: Convert this function into payable to make bidders place a deposit in order to force them to claim their ERC20
     */
    function auctionBid(uint256 _priceInWei, uint256 _amountOfERC20) public {
        require(msg.sender != auctionOwner, "Owner cannot deposit");
        require(block.timestamp <= auctionDeadline, "auction finished");
        require(_amountOfERC20 <= totalSupply, "Amount must be lower than supply");

        listOfBids.push(bidStruct({
            time: block.timestamp,
            bidder: msg.sender,
            price: _priceInWei,
            amount: _amountOfERC20
        }));

        uint256 receiptID = listOfBids.length - 1;

        if (hashPriceTokens[_priceInWei] > 0) {
            // adding the amount to the hashPriceTokens hashmap
            hashPriceTokens[_priceInWei] = hashPriceTokens[_priceInWei] + _amountOfERC20;

            // adding the receipt to the hashPriceReceipts hashmap
            uint256[] storage tmpReceiptList = hashPriceReceipts[_priceInWei];
            tmpReceiptList.push(receiptID);
            hashPriceReceipts[_priceInWei] = tmpReceiptList;
        } else {
            // adding a new price to
            listOfPrices.push(_priceInWei);

            // adding the amount to the hashPriceTokens hashmap
            hashPriceTokens[_priceInWei] = _amountOfERC20;

            // adding the receipt to the hashPriceReceipts hashmap
            hashPriceReceipts[_priceInWei] = [receiptID];
        }

        // adding the receipt to the hashBidderReceipts hashmap
        if (hashBidderReceipts[msg.sender].length > 0) {
            uint256[] storage tmpReceiptList = hashBidderReceipts[msg.sender];
            tmpReceiptList.push(receiptID);
            hashBidderReceipts[msg.sender] = tmpReceiptList;
        } else {
            hashBidderReceipts[msg.sender] = [receiptID];
        }


        emit UserPlacedBid(msg.sender, _priceInWei, _amountOfERC20);
    }

    /**
     * @notice Function to transfer the ERC20 tokens to the winner
     * @param _bidderWinner address which will receive the ERC20, _amount the number of ERC20 sent
     */
    function transferERC20(address _bidderWinner, uint256 _amount) private {
        IERC20 erc20Token = IERC20(getERC20address());
        erc20Token.transfer(_bidderWinner, _amount);
        emit ERC20Sent(msg.sender, _bidderWinner, _amount);
    }

    /**
     * @notice Returns the Price to Pay and the Amount of ERC20 token the bidder will receive
     * @param _address the bidder address
     * @return a tuple with the total price and the amount
     */
    function getAmountAndPriceClaimableByBidder(address _address) public view returns(uint256, uint256) {
        uint256[] memory bidderBidReceipts = hashBidderReceipts[_address];
        uint256 tmpPrice;
        uint256 tmpAmount;
        
        uint256 minPriceonExecutinAuction = getCurrentMinPrice();

        for (uint i=0; i < bidderBidReceipts.length; i++) {
            bidStruct memory receiptStruct = listOfBids[bidderBidReceipts[i]];
            if (receiptStruct.price > minPriceonExecutinAuction || receiptStruct.price == minPriceonExecutinAuction  && hashPriceReceipts[receiptStruct.price].length == 1) {
                tmpPrice += receiptStruct.price * receiptStruct.amount;
                tmpAmount += receiptStruct.amount;
            }
        }

        return (tmpPrice, tmpAmount);
    }

    /**
     * @notice Function to claim the Bid and triggers the functions to send the ERC20 to the winner and the ETH to the Auction Owner
     * @dev TODO: Investigate if there is a more effecient way of checking if bidder has claimed their bids, than using hashBidderClaimed
     */
    function claimBid() public payable {
        require(!getIfAuctionIsActive(), "auction is running");
        require(!hashBidderClaimed[msg.sender], "bidder already claimed");
        hashBidderClaimed[msg.sender] =  true;
        uint256 bidPrice;
        uint256 claimableAmount;
        (bidPrice, claimableAmount) = getAmountAndPriceClaimableByBidder(msg.sender);
        require(claimableAmount > 0, "not owning any winner bid");
        require(msg.value >= bidPrice, "ETH not enough");
        payable(auctionOwner).transfer(msg.value);
        emit ETHSentToOwner(auctionOwner, msg.value);
        transferERC20(msg.sender, claimableAmount);
    }
}