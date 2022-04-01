pragma solidity ^0.5.3;
import "./smartAuction.sol";

/* 
pre bidding phase: grace period, length = 30 (0 if debugging)
bidding phase: bid commit and withdraw
post bidding phase: bid opening
end phase: finalize
*/
contract vickeryAuction is smartAuction{
    uint deposit; //deposit requirement for committing a bid
    uint bidCommitLength; //block time length of the subphase bid committment, on which bidders submit a commitment to their bid (PART OF BIDDING TIME)
    uint bidWithdrawLength; //block time length of the subphase bid withdrawal, on which bidders can withdraw their bids, by paying a fee (PART OF BIDDING TIME)
    uint bidOpeningLength; //block time length of the opening phase, on which all bidders should reveal their bids (IT IS THE POST BIDDING PHASE RENAMED)
    
    uint price; //amount that the winner has to pay (the second highest bid)
    mapping(address => bytes32) commits; //keep track of the hashed committments

    constructor(address payable seller, uint _reservePrice, uint _deposit, uint _bidCommitLength, uint _bidWithdrawLength, uint _bidOpeningLength) 
                    smartAuction(seller, _reservePrice, 20, _bidCommitLength + _bidWithdrawLength, _bidOpeningLength) public {
        deposit = _deposit;
        
        bidCommitLength = _bidCommitLength;
        bidWithdrawLength = _bidWithdrawLength;
        bidOpeningLength = _bidOpeningLength;
    }
    
    //commit using an hashed message to ensure the bid's secrecy
    function bid(bytes32 hashedMsg) payable public{
        super.bidConditions();
        require((creationBlock + preBiddingLength + bidCommitLength) >= block.number, "It is not bid committment time anymore!");
        
        uint depositAmount = msg.value;
        address bidder = msg.sender;
        require(commits[bidder] == bytes32(0), "You have already made a committment!");
        require(depositAmount >= deposit, "Deposit amount is not enough!");
        
        bidders[bidder] = depositAmount; //saving the deposit requirement
        commits[bidder] = hashedMsg; //saving the hashed committment
    }
    
    //Debug method used to generate and send hashed committment
    function test_bid(bytes32 nonce, uint bidAmount) payable public{
        bid(keccak256(abi.encodePacked(nonce, bidAmount)));
    }
    
    function withdraw() public {
        super.bidConditions(); //Because in this case the withdraw require the same conditions of bids!
        require((creationBlock + preBiddingLength + bidCommitLength) < block.number, "It is still bid committment time!");
        require((creationBlock + preBiddingLength + bidCommitLength + bidWithdrawLength) >= block.number, "It is not withdraw time anymore!");
        
        address payable bidder = msg.sender;
        uint refundAmount = bidders[bidder];
        
        if(refundAmount != 1){
            refundAmount = refundAmount/2; //pay half deposit as a fee
        }
        commits[bidder] = bytes32(0); //remove committment
        
        refundTo(bidder, refundAmount);
    }
    
    function reveal(bytes32 nonce) payable public{
        require(getCurrentPhase(block.number) == phase.postBidding, "It is not reveal time yet");
        require(commits[msg.sender] != bytes32(0), "You didn't bid in this auction!");
        
        uint amount = msg.value;
        address payable bidder = msg.sender;
        bytes32 hashedMsg = keccak256(abi.encodePacked(nonce, amount)); //sha3 is deprecated!
        require(hashedMsg == commits[bidder], "The amount doesn't match with the committment!");
        
        refundTo(bidder, bidders[bidder]); //refund full deposit
        bidders[bidder] += amount; //add bid amount
        
        //dinamically set the winner and the price
        if(amount > winningBid){
            
            if(winningBidder != address(0)){ //check if there was already a winner: if so, refund him
                refundTo(winningBidder, winningBid); //refund bid amount
                price = winningBid;
            }
            
            winningBid = amount;
            winningBidder = bidder;
            emit newHighestBidEvent(bidder, amount);
        }
        else{
            if(amount > price){ //check if your bid will be the final price
                price = amount;
            }
            
            refundTo(bidder, bidders[bidder]); //refund bid amount
        }
    }
    
    //Give back the remaining to the winning bidder
    function finalize() public{
        super.finalizeConditions();
        //if you are here, no re-entrancy problem, because finalized has been set to true!
        
        if(winningBid >= reservePrice){
            if(price == 0){ //check if there was one bidder only
                price = reservePrice;
            }
            
            seller.transfer(price);
            
            bidders[winningBidder] -= price;
            refundTo(winningBidder, bidders[winningBidder]);

            emit finalizeEvent(winningBidder, price);
        }
        else{
            emit noWinnerEvent();
            if(winningBid != 0){
                refundTo(winningBidder, winningBid);
            }
        }
    }

    //Checks if a certain user committed to the auction
    function userCommitted(address user) public view returns(bool){
        return commits[user] != 0;
    }

    //Getters

    function getDeposit() public view returns(uint){
        return deposit;
    }

    function getBidCommitLength() public view returns(uint){
        return bidCommitLength;
    }

    function getBidWithdrawLength() public view returns(uint){
        return bidWithdrawLength;
    }

    function getBidOpeningLength() public view returns(uint){
        return bidOpeningLength;
    }
}
