// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0<0.9.0;

contract Estore{
    struct Auction{
        uint id;
        address payable seller;
        string name;
        string description;
        uint min;
        uint[] offerIds;
        uint bestOfferId;
    }

    struct Offer{
        uint id;
        uint auctionId;
        address payable buyer;
        uint price;
    }

    mapping(uint=>Auction) private auctions;
    mapping(uint=>Offer) private offers;
    mapping (address => uint[]) private auctionList;
    mapping(address => uint[]) private offerList;

    uint private newAuctionId = 1;
    uint private newOfferId = 1;

    modifier auctionExist(uint _auctionId){
        require(_auctionId >0 && _auctionId < newAuctionId,"Auction doesn't exist");
        _;
    }

    function createAuction(string calldata _name, string calldata _description, uint _min) external {
        require(_min>0,"min bid must be greater than 0");
        uint[] memory offerIds = new uint[](0);
        auctions[newAuctionId] = Auction(newAuctionId, payable(msg.sender),_name, _description, _min, offerIds, 0);
        auctionList[msg.sender].push(newAuctionId);
        newAuctionId++;
    }

    function createOffer(uint _auctionId)external payable auctionExist(_auctionId){
        Auction storage auction = auctions[_auctionId];
        Offer storage bestOffer = offers[auction.bestOfferId];
        require(msg.value >= auction.min && msg.value > bestOffer.price,"price must be greater than min and best offer");
        auction.bestOfferId = newOfferId;
        auction.offerIds.push(newOfferId);

        offers[newOfferId] = Offer(newOfferId, _auctionId, payable(msg.sender), msg.value);
        offerList[msg.sender].push(newOfferId);
        newOfferId++;

    }

    function transaction(uint _auctionId) external auctionExist(_auctionId){
        Auction storage auction = auctions[_auctionId];
        Offer storage bestOffer = offers[auction.bestOfferId];

        for(uint i=0; i < auction.offerIds.length; i++){
            uint offerId = auction.offerIds[i];
            if(offerId != auction.bestOfferId){
                Offer storage offer = offers[offerId];
                offer.buyer.transfer(offer.price);
            }
        }
        auction.seller.transfer(bestOffer.price);
    }

    function getAuctions() external view returns (Auction[] memory){
        Auction[] memory _auctions = new Auction[](newAuctionId -1);

        for(uint i = 1; i < newAuctionId; i++){
            _auctions[i-1] = auctions[i];
        }
        return _auctions;
    }

    function getUserAuction(address _user) external view returns(Auction[] memory){
        uint[] storage userAuctionIds = auctionList[_user];
        Auction[] memory _auctions = new Auction[](userAuctionIds.length);
        for(uint i=0; i < userAuctionIds.length; i++){
            uint auctionId = userAuctionIds[i];
            _auctions[i] = auctions[auctionId];
        }
        return _auctions;
    }

    function getUserOffer(address _user) external view returns(Offer[] memory){
        uint[] storage userOfferIds = offerList[_user];
        Offer[] memory _offers = new Offer[](userOfferIds.length);
        for(uint i=0; i< userOfferIds.length; i++){
            uint offerId = userOfferIds[i];
            _offers[i] = offers[offerId];
        }
        return _offers;
    }
}


