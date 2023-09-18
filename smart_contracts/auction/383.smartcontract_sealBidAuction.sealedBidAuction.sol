//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC721 {
    function transferFrom(
        address _from, 
        address _to, 
        uint _vaseId
    ) external;
}

contract SealBidAuction{

    event Start();
    event Bid(address indexed sender, uint amount);
    event Refund(address indexed bidder, uint amount);
    event End(address winner, uint amount);

   
    
    IERC721 public Vase;
    uint public VaseId;

    address payable public immutable seller;
    uint public reservedPrice;
    uint public AuctionEndsAt;
    bool public started;
    bool public ended;


     address public highestBidder;
     uint highestBid;


    mapping(address => uint) public bids;

      
     constructor(uint _reservedPrice, address _vase, uint _vaseId) {
        seller = payable(msg.sender);
        reservedPrice = _reservedPrice;

        Vase = IERC721(_vase);
        VaseId = _vaseId;
        
        highestBid = _reservedPrice;
 }

    function startBid() external {
        require(!started, "started");
        require(msg.sender == seller, "not seller");

        Vase.transferFrom(msg.sender, address(this), VaseId);
        started = true;
        AuctionEndsAt = uint32(block.timestamp + 180);

        emit Start();

     

        
    }

     function bid() external payable{
        require(msg.sender != seller, "Nor dey Zuzu, Seller Cannot Bid.");
        require(started, "not started");
        require(block.timestamp < AuctionEndsAt, "ended");
        require(msg.value > reservedPrice, " Must be higher than resevered price ");
        require(msg.sender != address(0)," Address zero not allowed!!!");
        
        if(msg.value > highestBid){
        highestBidder = msg.sender;
        highestBid = msg.value;
        }


        bids[msg.sender] += highestBid;

        emit Bid(msg.sender, msg.value);
    }


    function end() external {
        require(started, "not started");
        require(block.timestamp >= AuctionEndsAt, "not ended");
        require(!ended,"ended");

        ended = true;
        if (highestBidder != address(0)) {
            Vase.transferFrom(address(this), highestBidder, VaseId);
            seller.transfer(highestBid);
        } else {
            Vase.transferFrom(address(this), seller, VaseId);

        }
        emit End(highestBidder, highestBid);
    }

      function refund() external {
        require(block.timestamp >= AuctionEndsAt, "not ended");
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Refund(msg.sender, bal);

    }

}