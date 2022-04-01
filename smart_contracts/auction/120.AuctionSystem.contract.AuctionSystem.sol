pragma solidity ^0.4.18;

contract Auction{
    
    address organizer;
    
    uint256 totalItems = 0; 
    uint256 totalUsers = 0;
    
    mapping(address=>User) Users;   //users taking part in auction
    mapping(uint256=>Item) AuctionPot; //pot of items

    mapping(address=>bool) userExist; //to check is user already exist
    mapping(uint256=>uint256) i2r;  //mapping from itemsOwnedID to realItemID
    
    function Auction() public{
        organizer = msg.sender;
        //Adding Organizer to User
        Users[organizer].name = "Admin";
        Users[organizer].coins = 0;
        userExist[organizer] = true;
    }
    
    struct Item{
        string name;
        uint256 cost;
        address ownerAddress;
    }
    
    struct User{
        string name;
        mapping(uint256=>Item) itemsOwned; //item id is mapped to item
        uint256 coins;
        uint256 numberItemsOwned;
    }
    
    
    //only organizer can add Items
    function addItemToAuction(string name, uint256 cost, address ownerAddress) public{
        if(msg.sender == organizer){
            totalItems = totalItems + 1;
            AuctionPot[totalItems].name = name;
            AuctionPot[totalItems].cost = cost;
            AuctionPot[totalItems].ownerAddress = ownerAddress;
        }
        else throw;
    }
    //only organizer can add users
    function addUserToAuction(string name, address userAddress, uint256 coins) public{
        if(msg.sender == organizer && !userExist[userAddress]){
            Users[userAddress].name = name;
            Users[userAddress].coins = coins;
            userExist[userAddress] = true;
            totalUsers++;
        }
        else throw;
    }
    function itemBuy(uint itemID, address userAddress) public{
        User user = Users[userAddress];
        if(user.coins >= AuctionPot[itemID].cost){
            user.itemsOwned[user.numberItemsOwned++] = AuctionPot[itemID];  //updating users itemsOwned
            AuctionPot[itemID].ownerAdress = userAddress;   //updating item ownerAdress
            i2r[user.numberItemsOwned - 1] = itemID;
            user.coins -= AuctionPot[itemID].cost;
            Users[organizer].coins += AuctionPot[itemID].cost; //adding money to organizer
        }
        else throw;
    }
    
    function getItem(uint itemID) public constant returns (string,uint256,address){
        return (AuctionPot[itemID].name,AuctionPot[itemID].cost,AuctionPot[itemID].ownerAdress);
    }
    
    function getUser(address userAddress) public constant returns (string,uint256,uint[]){
        uint[]  myItems;
        for(uint256 i = 0; i < Users[userAddress].numberItemsOwned;i++){
            myItems.push(i2r[i]);
        }
        return (Users[userAddress].name,Users[userAddress].coins,myItems);
    }
}
