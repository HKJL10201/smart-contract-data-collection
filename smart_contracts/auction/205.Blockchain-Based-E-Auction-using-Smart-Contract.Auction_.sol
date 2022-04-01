pragma solidity ^0.4.17; 

contract Auction {

     struct Item {
        uint itemId; // id of the item
        uint[4] itemTokens; //tokens bid in favor of the item
    }

    struct Person {
        uint remainingTokens; // tokens remaining with bidder
        uint personId; // it serves as tokenId as well
        address addr;//address of the bidder
    }
 
    mapping(address => Person) tokenDetails; //address to person
    Person [4] bidders;//Array containing 4 person objects

    Item items;//item object
    address public winners;//address of winner
    Person public beneficiary;//owner of the smart contract
    
    uint public auctionClose;
    uint topBid;
    address topBidders;
    mapping(address => uint) returnsPending; // # tokens pending to be returned to each person
    uint bidderCount=0;//counter
    
    bool auctionComplete;
    bool winnersDeclared;
    
    modifier onlyowner(address _adr){ require(_adr == beneficiary.addr); _; }
 
    modifier onlybidders(address _addr){ require(_addr != beneficiary.addr); _; }
    //functions
    function Auction(uint _biddingTime) public payable{ //constructor

        //Part 1 Task 1. Initialize beneficiary with address of smart contract’s owner 
        beneficiary.addr = msg.sender;
        auctionClose = now + _biddingTime;
        //Hint. In the constructor,"msg.sender" is the address of the owner.

        uint[4] memory emptyArray;
        items = Item({itemId:0,itemTokens:emptyArray});
        //** End code here**/
    }

    function register() public payable onlybidders(msg.sender) {
        
        require(now <= auctionClose);
        uint newRegister=0;
        for(uint b=0; b<bidderCount; b++) {
            if (bidders[b].addr == msg.sender) newRegister++;
        }
        
        require(newRegister == 0);
        bidders[bidderCount].personId = bidderCount;
        bidders[bidderCount].addr = msg.sender;

        //Part 1 Task 3. Initialize the address of the bidder
        /*Hint. Here the bidders[bidderCount].addr should be initialized with address of the registrant.*/
        bidders[bidderCount].remainingTokens = 5; // only 5 tokens
        tokenDetails[msg.sender]=bidders[bidderCount];
        bidderCount++;
    }

    function bid(uint _count) public payable {

        require(now <= auctionClose);
        /*
        Two conditions below:
        1. If the number of tokens remaining with the bidder is <
            count of tokens bid, revert
        2. If there are no tokens remaining with the bidder,
            revert.
        Hint: "tokenDetails[msg.sender].remainingTokens" gives the
        details of the number of tokens remaining with the bidder.
        */
 
        if (tokenDetails[msg.sender].remainingTokens < _count || tokenDetails[msg.sender].remainingTokens == 0) revert();
        if(_count !=0) returnsPending[msg.sender] += _count;

        /*Part 1 Task 5. Decrement the remainingTokens by the number of tokens bid
        Hint. "tokenDetails[msg.sender].remainingTokens" should be decremented by "_count". */

        tokenDetails[msg.sender].remainingTokens -= _count;
        bidders[tokenDetails[msg.sender].personId].remainingTokens=
        tokenDetails[msg.sender].remainingTokens; //updating the same balance in bidders map.
        
        items.itemTokens[tokenDetails[msg.sender].personId]= _count;
    }

    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }

    function revealWinners() private returns (bool)  {

        topBid = items.itemTokens[0];
        topBidders = bidders[0].addr;
        for(uint i=1; i<bidderCount; i++) {
            topBid = max(topBid,items.itemTokens[i]);
            if(topBid == items.itemTokens[i]) topBidders = bidders[i].addr;
        }
        
        winners = topBidders;
        for(uint t=0; t<bidderCount; t++) {
            if (bidders[t].addr != winners) {
                bidders[t].remainingTokens += returnsPending[bidders[t].addr];
                tokenDetails[bidders[t].addr].remainingTokens = bidders[t].remainingTokens;
            }
        }
        return true;
    }
 
    function withdraw() public onlybidders(msg.sender) returns (bool) {
        
        require(now <= auctionClose);
        uint bidAmount = returnsPending[msg.sender];
        if(bidAmount>0){
            returnsPending[msg.sender]=0;
            items.itemTokens[tokenDetails[msg.sender].personId] -= bidAmount;
            tokenDetails[msg.sender].remainingTokens += bidAmount;
            bidders[tokenDetails[msg.sender].personId].remainingTokens = tokenDetails[msg.sender].remainingTokens;
            }
        return true;
    }

    function auctionClose() public onlyowner(msg.sender) { //Have to be called by beneficiary after auction time is completed
        
        //1. conditions
        require(now >= auctionClose); //auction did not end yet
        require(!auctionComplete); //function shouldn't already been called
        
        //2. Effects
        auctionComplete = true;
        winnersDeclared = revealWinners();
        
        //3. Interactions
        if(winnersDeclared) beneficiary.remainingTokens = topBid;
    }

    function getPersonDetails(uint id) public constant returns(uint,uint,address){
        return (bidders[id].remainingTokens,bidders[id].personId,bidders[id].addr);
    }

}