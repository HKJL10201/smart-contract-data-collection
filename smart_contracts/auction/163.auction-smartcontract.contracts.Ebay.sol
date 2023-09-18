// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Ebay {
    
    struct Auction {
        uint id;
        string name;
        string description;
        address payable seller;
        uint min;
        uint bestOfferId;
        uint[] offerIds;
    }

    struct Offer {
        uint id;
        uint auctionId;
        address payable buyer;
        uint price;
    }

    mapping (uint => Auction) private auctions;
    mapping (uint => Offer) private offers;
    mapping (address => uint[]) private auctionList;
    mapping (address => uint[]) private offerList;

    uint private newAuctionId = 1;
    uint private newOfferId = 1;

    function createAuction(string calldata _name, string calldata _description, uint _min) external{
        require(_min > 0, "min must be greater than zero");
        uint[] memory offerIds = new uint[](0);

        auctions[newAuctionId] = Auction(newAuctionId, _name, _description, payable(msg.sender), _min, 0, offerIds);
        auctionList[msg.sender].push(newAuctionId);
        newAuctionId++;
    }

    function createOffer(uint _auctionId) external payable auctionExists(_auctionId){
        Auction storage auction = auctions[_auctionId];
        Offer storage bestOffer = offers[auction.bestOfferId];

        require(msg.value > auction.min && msg.value > bestOffer.price, "msg.value must be greater than min and best offer");

        auction.bestOfferId = newOfferId;
        auction.offerIds.push(newOfferId);

        offers[newOfferId] = Offer(newOfferId, _auctionId, payable(msg.sender), msg.value);
        offerList[msg.sender].push(newOfferId);
        newOfferId++;
    }

    function transaction(uint _auctionId) external auctionExists(_auctionId){

        Auction storage auction = auctions[_auctionId];
        Offer storage bestOffer = offers[auction.bestOfferId];

        for (uint i = 0; i < auction.offerIds.length; i++) {
            uint offerId = auction.offerIds[i];

            if (offerId != auction.bestOfferId) {
                Offer storage offer = offers[offerId];
                offer.buyer.transfer(offer.price);
            }

        }

        auction.seller.transfer(bestOffer.price);

    }

    function getAuction(uint _auctionId) external view returns(Auction memory){
        return auctions[_auctionId];
    }

    function getAuctions() external view returns(Auction[] memory) {
        Auction[] memory _auctions = new Auction[](newAuctionId - 1);
        
        for (uint i=1; i < newAuctionId; i++) {
            _auctions[i - 1] = auctions[i];
        }

        return _auctions;
    }

    function getUserAuctions(address _user) external view  returns (Auction[] memory){
        uint[] storage userAuctionIds = auctionList[_user];

        Auction[] memory _auctions = new Auction[](userAuctionIds.length);

        for (uint i = 0; i < userAuctionIds.length; i++) 
        {
            uint auctionId = userAuctionIds[i];

            _auctions[i] = auctions[auctionId];
        }

        return _auctions;
    }



    function getUserOffers(address _user) external view  returns (Offer[] memory){

        uint[] storage _userOfferIds = offerList[_user];

        Offer[] memory _offers = new Offer[](_userOfferIds.length);

        for (uint i=0; i < _userOfferIds.length; i++) 
        {
            uint offerId = _userOfferIds[i];

            _offers[i] = offers[offerId];
        }

        return _offers;
    }

    modifier auctionExists(uint _auctionId) {
        require(_auctionId > 0 && _auctionId < newAuctionId, "Auction does not exist");
        _;
    }

}