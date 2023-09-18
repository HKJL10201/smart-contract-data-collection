contract EtherAuction {
	address public winner;
	uint public highestBid;
	uint public nextSale;
	uint public startBlock;
	uint public duration;
	uint public rollOverFactor;
	/// Makes an EtherAuction contract with a given duration in blocks and rollOverFactor, 
	/// ie., the amount of a given bid that is kept by the contract.
	function EtherAuction(uint _duration, uint _rollOverFactor) {
		startBlock = block.number;
		winner = msg.sender;
		highestBid = 0;
		nextSale = 0;
		duration = _duration;
		rollOverFactor = _rollOverFactor;
	}
	/// Fired when a new winning bid is given
	event WinningBid(address newWinner, uint bid);
	/// Fired when a new acution starts
	event NewAuction(uint onSale, uint start, uint duration);
	/// Helpful to tell us what amount of ether is on sale
	function onSale() constant returns(uint) {
		return this.balance - nextSale;
	}
	/// Helpful to tell us when the auction ends
	function endBlock() constant returns(uint) {
		return startBlock + duration;
	}
	/// Makes a new bid for the ether on sale  
	function bid() {
		if (startBlock + duration <= block.number) {throw;}
		if (msg.value <= highestBid) {throw;}
		var prevHighest = highestBid;
		highestBid = msg.value;
		if (prevHighest > 0) {
			if (!winner.send(prevHighest - prevHighest/rollOverFactor)) {throw;}
			nextSale = nextSale - (prevHighest - prevHighest/rollOverFactor);
		}		
		nextSale = nextSale + highestBid;
		winner = msg.sender;
		WinningBid(winner, highestBid);
	}
	/// Claims the ether on sale for the winner and starts a new auction
	function claim() {
		if (startBlock + duration > block.number) {throw;}
		if (highestBid > 0) {
			nextSale = nextSale;
			if (!winner.send(this.balance - nextSale)) {throw;}
		}
		highestBid = 0;
		nextSale = 0;
		startBlock = block.number;
		NewAuction(this.balance, startBlock, duration);
	}
	/// We will fallback to a bid
	function() {
		bid();
	}
}