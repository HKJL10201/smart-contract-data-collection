//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract AuctionCreator{
    Auction[] public auctions;
    function createAuction() public{
        Auction newauction = new Auction(msg.sender);
        auctions.push(newauction);
    }
}

contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    enum State {started , Running , Ended , Cancelled}
    State public auctionState;
   
    enum OwnerState {received , didntreceived}
    OwnerState public ownerstate;
    uint public highestBindingBid;

    address payable public highestBidder;

    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor(address _owner){
        owner = payable(_owner);
        auctionState = State.Running;
        ownerstate = OwnerState.didntreceived;
        startBlock = block.number;
        endBlock = block.number + 4;
        ipfsHash = "";
        bidIncrement = 1 ether;
    }

    modifier notOwner(){
        require(msg.sender != owner , "Owner cannot run this function");
        _;
    }
   
    modifier onlyOwner(){
        require(msg.sender == owner, "You aren't owner of this auction");
        _;
    }
   
    modifier afterStart(){
        require(block.number >= startBlock , "Auction isn't started yet");
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock , "Auction already ended");
        _;
    }
    
    function min(uint a, uint b) internal pure returns (uint){
            if(a>b){
                return b;
            }else{
                return a;
            }
                
    }
    
    function cancelAuction() public onlyOwner{
        auctionState = State.Cancelled;
    }

    function placeBid() public payable notOwner afterStart beforeEnd{
        require(auctionState == State.Running, "Auction isn't running");
        require(msg.value >= 100);
        //Zero is deafult value of any Address in mapping
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid>highestBindingBid);
        bids[msg.sender] = currentBid;
        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{
            highestBindingBid = min (currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuction() public {
        require(auctionState == State.Cancelled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0 );

        address payable recipient ;

        uint value ;

        if(auctionState == State.Cancelled){
            recipient = payable(msg.sender);
            value = bids[msg.sender];
            
        }else {
            if(msg.sender == owner){
               require(ownerstate == OwnerState.didntreceived);
                recipient = payable (msg.sender );
                value = highestBindingBid; 
                ownerstate = OwnerState.received;
            }else{
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[recipient] - highestBindingBid;
                    
                }else{
                    recipient = payable(msg.sender);
                    value = bids[recipient];
                    
                }
                
            }
        }
        bids[msg.sender]=0;
        recipient.transfer(value);
    }

}
