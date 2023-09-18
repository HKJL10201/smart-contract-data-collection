pragma solidity ^0.4.18;

contract SimpleAuction {
    address public  beneficiary; // address that created the auction
    string end_date; //end date of the auction
    string product_name; // product description
    string product_code;

    address public highestBidder; //address that has the highest bidder
    uint public highestBid; // their bid value

    mapping(address => uint) pendingReturns;  //map the address and their bids to refund the money to those who lost
    bool ended;
    
    //event handlers
    event HighestBidIncreased(address bidder, uint amount); 
    event AuctionEnded(address winner, uint amount);
    
    //constructor for simple auction
    function SimpleAuction(address _beneficiary, string _end_date, string _product_name, string _product_code) public {
        beneficiary = _beneficiary;
        end_date = _end_date;
        product_name = _product_name;
        product_code = _product_code;
    }

//if the msg value is higher than the current highest bid, we replace the highest bid information with the new highest bid
function bid() public payable {
        pendingReturns[msg.sender] += msg.value; // keep track of bids
        if(msg.value > highestBid){
        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidIncreased(msg.sender, msg.value);    
        }
} 


function withdraw() public {
         uint amount = pendingReturns[msg.sender]; //get the amount that the bidder bid
         if(ended){ // check if the auction ended
        if (msg.sender != highestBidder) { //if sender is not the highest bidder
        msg.sender.transfer(amount); //give back their ether
        pendingReturns[msg.sender] = 0; // after they get their refund, turn value to 0
        }
         }
    
    }


function auctionEnd() public  { 
    if(msg.sender == beneficiary){  // only allows the owner to call this function
        if(!ended){ //check if auction ended already? (in case owner calls this function twice)
            ended = true; //ended will be true
        AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid); //get the money from the highest bidder
        }
    }
}
//users can see the product 
function product() public view returns (string){
    return product_name;
}

//users can see the end dae of the auction 
function EndDate() public view returns (string){
    return end_date;
}

function getProduct() public view returns (string){
    if(ended){ // did auction end?
        if(msg.sender == highestBidder){ //is the sender the highest bidder?
            return product_code; //if yes, return code for vbucks
        }
    }
}
    
}