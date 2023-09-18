pragma solidity ^0.8.0;

contract Auction{

    address payable public manager; 
    uint public start_time; // for start time
    uint public end_time; // for end time
    mapping(address=>uint) public bids; // storing bidders

    enum state {running, cancelled, end} state public auction_state; // auction status
    uint public highestBindingBid; // highest payable bid
    uint public increment; // increment required in bid to become highest bid
    address payable public highestBidder;

    constructor(){
        manager=payable(msg.sender); // person who deploy would be manager
        auction_state = state.running; // state changed to running
        start_time = block.timestamp;
        end_time = start_time + 7 days; // auction would last for 1 week
        increment = 1 ether;
    }

    modifier onlyManager() {
        require(msg.sender==manager);
        _;
    }

    modifier started() {
        require(block.timestamp>start_time);
        _;
    }

    modifier notEnd() {
        require(block.timestamp<end_time);
        _;
    }

    function cancel() public onlyManager{
        auction_state = state.cancelled;
    }

    function end() public onlyManager{
        auction_state = state.end;
    }

    // since solidity don't have built-in function for min
    function min(uint a, uint b) pure private returns(uint){
        if(a<b){
            return a;
        }
        else{
            return b;
        }
    }

    // bidders will call this function to bid, bid should be after start and before end
    function bid() payable public started notEnd{

        require(auction_state == state.running && msg.value > 0.1 ether && msg.sender!=manager); // auction should be running, min. bid is 0.1 ether, manager can't bid

        uint currentBid = bids[msg.sender] + msg.value; // if no previous bid by bidder, value from map would be 0
        require(currentBid > highestBindingBid); // if current bid is not greater then the highest payable bid, we will not proceed

        bids[msg.sender] = currentBid; // storing bid according to user address

        if(currentBid>bids[highestBidder]){
            // if the bid is greater than the previous highest bid, highest payable bid would be changed accordingly
            highestBindingBid = bids[highestBidder]+increment;
            // highest bidder would also be updated
            highestBidder = payable(msg.sender);
        }

        else{
            // if the bid is lesser than the previous highest bid, highest payable bid would be updated according to minimum. 
            // highest bidder don't have to pay whole amount, he will pay highest payable bid
            highestBindingBid = min(currentBid+increment, bids[highestBidder]);
        }
    }

    function finalizeAuction() payable public{
        require(block.timestamp>end_time || auction_state == state.cancelled || auction_state == state.end);
        require(msg.sender == manager || bids[msg.sender] > 0);

        // value to be transferred at the end
        uint transferValue;
        // person whom to be transferred
        address payable person;

        // if the auction would end successfully
        if(auction_state != state.cancelled){

            // if manager called this, he will get the highest payable bid
            if(msg.sender == manager){
                person = manager;
                transferValue = highestBindingBid;
            }

            // else person could be highest bidder, or any other bidder
            else{
                // if higher bidder calls this, he will get the amount what is left after paying the highest payable bid
                if(msg.sender == highestBidder){
                    person = highestBidder;
                    transferValue = bids[highestBidder]-highestBindingBid;
                }
                // else, everyone will get their contributed amount
                else{
                    person = payable(msg.sender);
                    transferValue = bids[person];
                }
            }
        }
        
        // if auction is cancelled, everyone can claim their amount by calling this function.
        // they will get what they bid in the starting
        else{
            person = payable(msg.sender);
            transferValue = bids[person];
        }
        person.transfer(transferValue);
        // value changed to 0 so that he can't claim again
        bids[person] = 0;
    }
}