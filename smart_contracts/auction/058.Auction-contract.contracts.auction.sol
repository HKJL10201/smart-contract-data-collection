//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";

contract auction {
    //@author: Blackadam
    //the address is an nft contract address
    IERC721 nftaddress;
    // address of the nftowner
    address nftOwner;
    //address nft;
    //the token id
    uint tokenId;
    //the price the owner is auctioning the nft for
    uint public setPrice;


    constructor(IERC721 _addressOfNFT, uint itemId, uint price){
        require(price > 0, "Your set price must be greter than 0");
        nftaddress = IERC721(_addressOfNFT);
        tokenId = itemId;
        setPrice = price;
        nftOwner = msg.sender;
    }

    // this monitors the state of the auction
    bool auctionStarted;
    //this keep the state of the address of the highestbidder
    address public highestBidder;
    //this keep the state of the current highestbid
    uint public HighestBid;

    //this stores the address of all bidders
    address[] allbidders;
    
    //This mapping is used to track the amount each bidder and the amount they bid
    mapping(address => uint) bidderDetails;
    //this is used to set the time for the auction
    uint timeFrame = block.timestamp + 180 seconds;

    //  This is used to restrict some functions the owner of the contract
    modifier onlyOwner(){
        require(msg.sender == nftOwner, "Access denied");
        _;
    }
    //this is used to check if the auction is still live or not
    modifier timeElapsed(){
        require(block.timestamp < timeFrame, "Auction ended");
        _;
    }



    //this function allow the nftOwner to begins the auction
    function nftAuction() external onlyOwner {
    //this check if an auction is currently going on to prevent multiple auction at the same time
        require(!auctionStarted, "There is an auction going on presently");
    //this transfer the nft from the owner to the contract address
    //@notice: the contract must i've been approved to transfer the nft before this can be succesfull
        IERC721(nftaddress).transferFrom(nftOwner, address(this), tokenId);
    //set the state of the auction to true, so other auction isn't allowed
        auctionStarted = true;
        // return "auction started";
    }

    //The fucntion allows user to bid for the nft
    function bid() external payable timeElapsed{
    //this check if the auction has started to prevent users from wasting their bid
        require(auctionStarted == true, "No auction yet");
    //this requires that the amount bid must be bigger than the initial price of the auction
        require(msg.value > setPrice, "amount too low to start a bid");
    //because the setPrice isn't going to be updated.. and i want each new bid to be greater than the latest bid
    //this checked if the amount the user is trying to bid to be greater than the highest bid.
        require(msg.value > HighestBid, "amount too low for the current bid");
    //this keep tracks of the amount each bidder bids on the platform
    //this helps to know how much to be sent to each user at the end of the bid
        bidderDetails[msg.sender] += msg.value;
    //this update the highestbidder to the user
        highestBidder = msg.sender;
    //this update the highest bid to the amount the  user deposit/bid
        HighestBid = msg.value;
    //the address of all participant in the bid is kept in the array of allbidders
        allbidders.push(msg.sender);
    }


    //the withdrawal of bid is done here for all bidders except the user with the hughest bid
    function withdraw() external {
    //this check if the time for the auction has elapsed
        require(block.timestamp > timeFrame, "auction is still on");
    //this prevent the person with the highest bid from withdrawing his bid
    //@notice: if this isn't done the person with the highest bid can withdraw his bid and
    //still get the nft        
        require(msg.sender != highestBidder, "You can't withdraw champ, you got the nft");
    //getting amount that each user bids
    //@notice: if someone that didn't bid try to withdraw, the perosn will be transfered 0 ether
    //because his balnce in this contract is 0. so the person is just wasting his ether on transaction fee
        uint bidderBal = bidderDetails[msg.sender];
    //setting the balance of the bidder to 0, to prevent multiple withdrawal
        bidderDetails[msg.sender] = 0;
    //the amount bid is transfered back to the bidder
        payable(msg.sender).transfer(bidderBal);
    }

    //the nft is being transfered here
    function getNFTBid() external onlyOwner{
        //I'm checking if there was no bid for the nft...
        if(HighestBid <= setPrice){
        //The nft is being sent back to the owner
        //address(this)-> contract address 
            nftaddress.safeTransferFrom(address(this), nftOwner, tokenId);
        }
        else{
        //if there was a bid(HighestBid > setPrice)
        //nft is transfered from the contract address to the highestbidder address
            nftaddress.safeTransferFrom(address(this), highestBidder, tokenId);
        //the HighestBid is being transfered from the contract address to the nftOwner address
            payable(nftOwner).transfer(HighestBid);
        }
    }

    //this functions returns the contract balance 
    function contractBal() external view returns(uint){
            return address(this).balance;
    }

    //this function retuns all the addressses of all the bidders that participate in the auction
    function getAllBiiders() external view returns(address[] memory){
        return allbidders;
    }


}