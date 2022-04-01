//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Auctions service
/// @author Riccardo Magni
/// @notice This contract was created for educational purpose, its reliability is not guaranteed
/// @dev All functions calls are currently implemented without side effects

import "./SafeMath.sol";
import "./Governed.sol";

/**
* @title Auctioneer contract
* @dev This is the implementation of the the auctioneers.
*/

contract Auctioneer is Governed {

    /// @dev Wrappers over Solidity's arithmetic operations with added overflow checks
    using SafeMath for uint;

    // -- State --
    mapping(address => bool) private _auctioneers;

    // -- Events --
    event AuctioneerAdded(address indexed account);
    event AuctioneerRemoved(address indexed account);

    // -- Modifier --
    modifier onlyAuctioneer() {
        require(isAuctioneer(msg.sender), "Only auctioneer can call");
        _;
    }

    /**
     * @dev Auction Constructor.
     */
    constructor () {

        /// @dev Set the owner of the contract
        Governed._initialize(msg.sender);

        /// @dev The governor is the default auctioneer
        _addAuctioneer(msg.sender);
    }

    /**
     * @dev Add a new auctioneer.
     * @param _account Address of the auctioneer
     */
    function addAuctioneer(address _account) external onlyGovernor {
        _addAuctioneer(_account);
    }

    /**
     * @dev Remove a auctioneer.
     * @param _account Address of the auctioneer
     */
    function removeAuctioneer(address _account) external onlyGovernor {
        _removeAuctioneer(_account);
    }

    /**
     * @dev Renounce to be a auctioneer.
     */
    function renounceAuctioneer() external {
        _removeAuctioneer(msg.sender);
    }

    /**
     * @dev Return if the `_account` is a auctioneer or not.
     * @param _account Address to check
     * @return True if the `_account` is auctioneer
     */
    function isAuctioneer(address _account) public view returns (bool) {
        return _auctioneers[_account];
    }

    /**
     * @dev Add a new auctioneer.
     * @param _account Address of the auctioneer
     */
    function _addAuctioneer(address _account) private {
        _auctioneers[_account] = true;
        emit AuctioneerAdded(_account);
    }

    /**
     * @dev Remove a auctioneer.
     * @param _account Address of the auctioneer
     */
    function _removeAuctioneer(address _account) private {
        _auctioneers[_account] = false;
        emit AuctioneerRemoved(_account);
    }
}

/**
* @title Auctions contract
* @dev This is the implementation of the the auctions service.
*/

contract Auctions is Auctioneer {

    /// @dev Wrappers over Solidity's arithmetic operations with added overflow checks
    using SafeMath for uint;

    // -- State --
    struct Auction {
        address payable beneficiary;
        string description;
        uint auctionEndTime;
        mapping( address => uint ) pendingReturns;
        uint numBids;
        uint highestBid;
        address highestBidder;
        bool completed;
    }

    uint public numAuctions;
    mapping( uint => Auction ) public auctions;
    string public companyName;

    mapping( uint => string) public receipts;
    uint public numReceipts;

    // -- Events --
    event NewAuctionCreated(uint indexed auctionID, address beneficiary, uint indexed auctionEndTime, uint indexed startingPrice);
    event HighestBidIncreased(uint indexed auctionID, address indexed bidder, uint indexed amount);
    event AuctionEnded(uint indexed auctionID, address indexed winner, uint indexed amount, address beneficiary);

    // Initialize variables
    constructor(string memory _companyName) {

        companyName = _companyName;
    }

    /**
     * @dev Create an auction
     * @param _beneficiary Beneficiary of the auction
     * @param _description Description of the auction
     * @param _startingPrice Starting price of the auction
     * @param _biddingTime Available time to bid
     * @return The uint of the auction ID associated with the auction just created
     */
    function newAuction( address payable _beneficiary, string memory _description, uint _startingPrice, uint _biddingTime ) external onlyAuctioneer returns (uint) {
        require(_beneficiary != address(0), "Zero address entered");
        require(_startingPrice >= 0, "Starting price has to be positive or null");
        require(_biddingTime > 0, "Available time to bid has to be greather than zero");

        uint auctionID = numAuctions++;
        Auction storage a = auctions[auctionID];
        a.beneficiary = _beneficiary;
        a.description = _description;
        a.highestBid = _startingPrice;
        a.auctionEndTime = block.timestamp.add(_biddingTime);

        emit NewAuctionCreated(auctionID, a.beneficiary, a.auctionEndTime, a.highestBid);

        return auctionID;
    }

    /**
     * @dev Bid
     * @param auctionID ID associated with the auction
     */

    function bid(uint auctionID) external payable {

        Auction storage a = auctions[auctionID];
        require(a.completed == false, "Auction has already ended!");
        require(a.auctionEndTime > 0, "AuctionID is not correct!");
        require(block.timestamp < a.auctionEndTime, "Deadline has been reached!");
        require(msg.value > a.highestBid, "Your bid value is lower than the highest bid");

        // Handle in case of starting price was set by auctioneer
        if (a.numBids != 0) {

            a.pendingReturns[a.highestBidder] = a.pendingReturns[a.highestBidder].add(a.highestBid);
        }
        a.highestBidder = msg.sender;
        a.highestBid = msg.value;
        a.numBids++;

        emit HighestBidIncreased(auctionID, msg.sender, msg.value);
    }

    /**
     * @dev Withdraw a bid that was overbid
     * @param auctionID ID associated with the auction
     * @return True if action was successfully executed, otherwise false
     */
    function withdraw(uint auctionID) external returns (bool) {

        Auction storage a = auctions[auctionID];
        require(a.auctionEndTime > 0, "AuctionID is not correct!");
        require(a.pendingReturns[msg.sender] > 0, "You have been already refunded or you are not a bidder of this auction or you are the current highest bidder");


        uint amount = a.pendingReturns[msg.sender];
        if (amount > 0) {

            a.pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                a.pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /**
     * @dev End an auction, transfer the highest bid to beneficiary and store hash of json receipt, only auctioneers
     * @param auctionID ID associated with the auction
     * @param hash string of json auction receipt
     */
    function auctionEnd(uint auctionID, string memory hash) external onlyAuctioneer{

        // Checks
        Auction storage a = auctions[auctionID];
        require(a.auctionEndTime > 0, "AuctionID is not correct!");
        require(bytes(hash).length != 0, "Hash string not passed");
        require(block.timestamp > a.auctionEndTime, "Auction has not reached its deadline yet");
        require(a.completed == false, "Auction has been already completed");


        // Effects
        a.completed = true;
        uint amount = a.highestBid;
        a.highestBid = 0;

        // Interaction
        a.beneficiary.transfer(amount);

        // Store hash
        receipts[auctionID] = hash;
        numReceipts++;

        emit AuctionEnded(auctionID, a.highestBidder, amount, a.beneficiary);
    }

}
