//1) Querying  [compulsory]
//2) Bi-sell function   [icing on the cake]
//3) bidding
//4) Team Contribution

pragma solidity ^0.6.0;

import "./AssetManager.sol";
import "./Ownable.sol";

contract AssetInterface is Ownable{

    enum assetState{Created, onAuction, Auctioned}

    uint oneEther = 1 ether;

    address newOwner;
    uint price;
    assetState state;
    uint NPA_ID;
    string assetOnAuction;
    string bankName;
    uint auctionID;
    uint eventType;
    string city;
    uint reservePrice;
    uint EMD;
    uint bidMultipliers;
    uint timeStamp;

    AssetManager assetManager;
    
    event newOwnerAssigned(address _newOwner);

    constructor(address _ownerAddress,
        AssetManager _parent,
        uint _NPA_ID,
        string memory _assetOnAuction,
        string memory _bankName, uint _auctionID, uint _eventType,
        string memory _city,
        uint _reservePrice, uint _EMD, uint _bidMultipliers,uint _timeStamp) public{
        assetManager = _parent;
        NPA_ID = _NPA_ID;
        assetOnAuction = _assetOnAuction;
        bankName=_bankName;
        auctionID=_auctionID;
        eventType = _eventType;
        city=_city;
        reservePrice=_reservePrice;
        EMD=_EMD;
        bidMultipliers=_bidMultipliers;
        timeStamp=_timeStamp;
        state = assetState.Created;
        Ownable.transferOwnership(_ownerAddress);
        price=2;

    }

    function getNPADetails() public view returns(uint _NPA_ID, string memory _assetOnAuction, string memory _bankName, uint _auctionID, uint _eventType, string memory _city, uint _reservePrice, uint _EMD, uint _bidMultipliers, uint _timeStamp){
        return (NPA_ID, assetOnAuction, bankName, auctionID, eventType, city, reservePrice, EMD, bidMultipliers, timeStamp);
    }

    function transferOwnership() public onlyOwner {
        require(newOwner!=address(0),"Cannot transfer onwership");
        payable(owner()).transfer(getBalance());
        Ownable.transferOwnership(newOwner);
        newOwner=address(0);
    }

    function getBalance() view public returns(uint){
        return payable(address(this)).balance;
    }

    function setNewOwner(address _newOwner) public onlyOwner {
        require(newOwner==address(0),"Previous ownership haven't transfered yet");
        newOwner=_newOwner;
        emit newOwnerAssigned(newOwner);
    }

    function getNewOwner() public view returns(address){
        return newOwner;
    }

    receive() external payable {
        require(((price*oneEther)==msg.value) && (msg.sender==newOwner&&msg.sender!=owner()),"Invalid Txn");
        newOwner==msg.sender;
    }
}
