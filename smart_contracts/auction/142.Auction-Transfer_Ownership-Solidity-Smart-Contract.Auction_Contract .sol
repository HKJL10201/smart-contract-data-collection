pragma solidity >=0.7.0 <0.9.0;

contract SimpleAuction{
	
	address payable public beneficiary;	// The initial address that deployed the contract.
	uint public auctionEndTime;		// The time at which the auction will end, we are requested to link block.timestamp + time in seconds below.


	address public highestBidder;		// The address that bid the highest value associated with the address.
	uint public highestBid;			// The highest value associated with the address.


	mapping(address => uint) public pendingReturns;		// This will show the selective address that had sent the value, so you can check this to know the
								// that and address has sent.


	bool ended = false;					// This will be used at the bottom function named auctionend.

	
	event HighestBidIncrease(address bidder, uint amount);	// Just a logging to the ethereum blockchain about the data.
	event AuctionEnded(address winner, uint amount);	// Just a logging to the ethereum blockchain about the data.


	constructor(uint _biddingTime, address payable _beneficiary){	// The deployed address will be the address to own the highest value once auction is ended.
		beneficiary = _beneficiary;				// _biddingtime takes the value and adds to the block.timestamp
		auctionEndTime = block.timestamp + _biddingTime;	// which is unix epoch time standard in seconds, so if you enter 120 - (2min will be the)
	}								// auction time limit


	function bid() public payable{					// Regular check for block.timestamp
		if(block.timestamp > auctionEndTime){
			revert("The auction has ended");		// revert is important feature that logs if the condition is false, so that we can read
		}							// human readable text logged by the code output.
		
		if(msg.value <= highestBid){
			revert("The bid is not up to the high value bidded");	// This will prevent any address that bids value lesser than the highest value bidded.
		}

		if(highestBid != 0){					// This sets the highestbid value, so the value cannot be 0, but whichever value is highest
			pendingReturns[highestBidder] += highestBid;	// Their address and the value will be noted down to the blockchain data.
		}							// This line sets the highestBidder and highestBid. (important)

		highestBidder = msg.sender;				// msg.sender will take note of all the address that have sent value to the bid.
		highestBid = msg.value;					// msg.value sets the address that sends value and link them intact.
		emit HighestBidIncrease(msg.sender, msg.value);		// Just a logging to the ethereum blockchain about the data.
	}

/* 

## THIS NOTE IS IMPORTANT FOR THE FUNCTION "withdraw(){}" TO UNDERSTAND BETTER:

payable(msg.sender).send(amount)   // payable is security feature of solidity, so its requested to use while returning the value to the address that bid lesser.
				   // the line tells us that to send the amount back,
				   // to the address that the bid is not up to the mark.

1. what if somebody does not want to withdraw the amount.	
2. what if the contract owner says keep your money in the contract it self and I will give you interest for it, and the address owner who bid less feels to not withdraw the money then we do this.


// The below ! condition is important coz it decides whether to or not to.

if (!payable(msg.sender).send(amount)) {	 // if this condition is not true then 
	pendingReturns[msg.sender] = amount;	// keep the ether in the function itself
	return false;				// and the if statement returns false
} 						// becoz the condition is false

return true;					// if the above (! blah blah) condition is true then the return value is set to true and the transfer is done
						// to the account that bid was low and willing to get back its ether.


*/


	function withdraw() public returns(bool){
		uint amount = pendingReturns[msg.sender];	// This is a local variable, that holds the value 
		if (amount > 0) {
			pendingReturns[msg.sender] = 0;		// This sets the value associated to a address with 0.

			if(!payable(msg.sender).send(amount)){	// This line is explained better in the above code.
				pendingReturns[msg.sender] = amount;
				return false;
			}
		}
		return true;
	}





	function auctionEnd() public{
		if(block.timestamp < auctionEndTime){		// Just a normal condition
			revert("The auction is not ended yet");
		}
		if (ended){					// remember ended was set to "false" at the beginning so
								// This line makes sure that you dont press the auctionEnd function twice and you get the
								// revert data (the auction is ended and do not press twice) 
			revert("The function auctionended has already called");
		}
		ended = true;					// once the condition is met ended is set to "true"
		emit AuctionEnded(highestBidder, highestBid);	// Just a regular logging to the ethereum blockchain.

		beneficiary.transfer(highestBid);		// This line is important because this transfers the value back to the account address
	}							// when the address owner who bid the value was not up to the mark and intends to get back his
}								// value to his address, once this function is pressed the value is sent back to the address.
