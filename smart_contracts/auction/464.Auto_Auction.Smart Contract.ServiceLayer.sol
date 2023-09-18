pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./BiddersDto.sol";
import "./CarDto.sol";
import "./CarAuction.sol";

contract ServiceLayer is ERC721Full, Ownable, BidderDto {
    
    constructor() ERC721Full("CarMarket", "CARS") public {}

    using Counters for Counters.Counter;

    Counters.Counter token_ids;

    address payable foundation_address = msg.sender;
    
  //  uint public gasFee = 422000;
    
    mapping(uint => CarAuction) auctions;
    mapping(uint => CarDto) public Cars;
    mapping(uint => Bidder[]) public bidList;
    
    event bidderAdded(uint token_id, address _bidderWallet, uint _bidAmount);
    event carAdded(string _vin, string _year, string _make, string _model, string _state, uint _miles, uint _accidents, uint _initial_value);

    
    function createAuction(uint token_id) public onlyOwner {
        auctions[token_id] = new CarAuction(foundation_address);
    }
    
    // Developer account - Pays for ALL GAS gasFee
    // Charge Auctioneers account every time a car is registered! 
    function registerCar(string memory _vin, string memory _year, 
    string memory _make, string memory _model, string memory _state,
    uint _miles, uint _accidents, uint _initial_value) public payable onlyOwner {
        token_ids.increment();
        uint token_id = token_ids.current();
        
        _mint(foundation_address, token_id);
       // _setTokenURI(token_id, uri);
        createAuction(token_id);
        Cars[token_id] = new CarDto(_vin,_year,_make,_model,_state,_miles,_accidents,_initial_value);
        emit carAdded(_vin,_year,_make,_model,_state,_miles,_accidents,_initial_value);
    }
    
    function addBidders(uint _bid_id, address _bidderWallet, uint _bidAmount) public {
        require(_bid_id == token_ids.current(), "Sorry please enter a correct token_id." );
        require(_bidAmount >= Cars[token_ids.current()].getCarInitialValue(), "Sorry got to increase your bid");
        
        uint token_id = token_ids.current();
        add(_bid_id, _bidderWallet,_bidAmount);
        emit bidderAdded(_bid_id,_bidderWallet,_bidAmount);
        
        bidList[token_id] = bidderList;
    }
    
    function viewCars(uint token_id) public view returns(uint){
        return Cars[token_id].getCarInitialValue();
    }
    
    function viewBiddersForTokenId(uint token_id) public view returns(Bidder memory){
        return bidList[token_id][0];
    }
    
    function endAuction(uint token_id) public {
        CarAuction auction = auctions[token_id];
        auction.auctionEnd();  //Sends Ether from bidder to the highest bidder
        safeTransferFrom(owner(), auction.highestBidder(), token_id); // Sends token to Bidder
    }

    function auctionEnded(uint token_id) public view returns(bool) {
        CarAuction auction = auctions[token_id];
        return auction.ended();
    }

    function highestBid(uint token_id) public view returns(uint) {
        CarAuction auction = auctions[token_id];
        return auction.highestBid();
    }
    
    function highestBidder(uint token_id) public view returns(address) {
    CarAuction auction = auctions[token_id];
    return auction.highestBidder();
    }

    function pendingReturn(uint token_id, address sender) public view returns(uint) {
        CarAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
    }
    
    
    //Developer account - Pays for ALL GAS gasFee
    // Charge bidders account every time a Bid is made! 
    function bid(uint token_id, address payable _bidderWallet) public payable {
        require(msg.value >= Cars[token_id].getCarInitialValue(), "Sorry got to increase your bid");
        CarAuction auction = auctions[token_id];
        //msg.value = _bidAmount;
        //bidMap[_bidderWallet].bidAmount = msg.value;
        auction.bid.value(msg.value)(_bidderWallet);
    }
    
    

    
    
}