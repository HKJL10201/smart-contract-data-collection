pragma solidity ^0.4.24;

contract Auction {

    struct bidder {
        address bidderAddress;
        uint tokenBought;
    }

    mapping (address => bidder) public bidders;
    mapping (bytes32 => uint) public highestBids;
    mapping (address => mapping (bytes32 => uint)) public usersBids;

    bytes32[] public itemList;

    uint public totalToken;
    uint public balanceTokens;
    uint public tokenPrice;
    
    constructor(uint _totalToken, uint _tokenPrice) public {
        totalToken = _totalToken;
        balanceTokens = _totalToken;
        tokenPrice = _tokenPrice;

        // enroll items for auction
        itemList.push("iphone7");
        itemList.push("iphone8");
        itemList.push("iphoneX");
        itemList.push("galaxyS9");
        itemList.push("galaxyNote9");
        itemList.push("LGG7");
    }

    function buy() public payable {
        uint tokensToBuy = msg.value / tokenPrice;
        require(tokensToBuy <= balanceTokens, "Not enough tokens.");
        bidders[msg.sender].bidderAddress = msg.sender;
        bidders[msg.sender].tokenBought += tokensToBuy;
        balanceTokens -= tokensToBuy;
    }

    function getHighestBids() public view returns (uint[]) {
        uint[] storage returnList;
        uint length = itemList.length;
        
        for( uint i = 0; i < length; i++) {
            returnList.push(highestBids[itemList[i]]);
        }

        return returnList;
    }

    function getUserBids() public view returns (uint[]) {
        uint[] storage returnList;
        uint length = itemList.length;

        for( uint i = 0; i < length; i++) {
            returnList.push(usersBids[msg.sender][itemList[i]]);
        }

        return returnList;
    }

    function bid(bytes32 itemName, uint tokenCountForBid) public {
        uint index = getItemIndex(itemName);
        require(index != uint(-1), "itemName is invalid");
        require(tokenCountForBid <= bidders[msg.sender].tokenBought + usersBids[msg.sender][itemName], "You don't have enough Token to bid");
        require(tokenCountForBid > highestBids[itemName], "New bid must be higher than previous highest bid");
        
        // Retrieve difference with previous bid
        bidders[msg.sender].tokenBought -= (tokenCountForBid - usersBids[msg.sender][itemName]);
        usersBids[msg.sender][itemName] = tokenCountForBid;
        highestBids[itemName] = tokenCountForBid;
    }

    function getItemIndex(bytes32 item) public view returns (uint) {
        uint length = itemList.length;
        for(uint i = 0; i < length ;i++) {
            if(itemList[i] == item) {
                return i;
            }
        }
        return uint(-1);
    }

    function getItemsInfo() public view returns (bytes32[]) {
        return itemList;
    }

    function getTotalToken() public view returns(uint) {
        return totalToken;
    }

    function getBalanceTokens() public view returns(uint) {
        return balanceTokens;
    }

    function getTokenPrice() public view returns(uint) {
        return tokenPrice;
    }

    function getTokenBought() public view returns(uint) {
        return bidders[msg.sender].tokenBought;
    }
}