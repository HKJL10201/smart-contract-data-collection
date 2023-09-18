pragma solidity >=0.4.9 <0.6.0;

contract IPL_Auction{

	string public playerName;
	address public player;
	uint public bidAmount;
	uint public minBid;
	address public highestBidder;
	uint public auctionEnd_time;
	string public bidderName;

	bool ended;

	mapping (address => uint) returnPrev_bid;

	event HighestBidIncreased(address bidder, uint amount);
	event AuctionEnded(address winner, uint amount);

	constructor(address _player, uint _biddingTime, string memory _playerName,uint _minBid) public{

		player =_player;
		auctionEnd_time = now + _biddingTime;
		playerName = _playerName;
		minBid=_minBid;

	}

	function bid (address _highestBidder,uint _bidAmount,string memory _bidderName) public  {
        
       /// highestBidder = _highestBidder;
        ///bidAmount = _bidAmount;
        highestBidder = _highestBidder;
        bidAmount = _bidAmount;
        
        bidderName=_bidderName;
		require (now <= auctionEnd_time);
		require (bidAmount > minBid);
		///bid func only works when bid is greater than the previous bid
		
		if (bidAmount != 0){

			returnPrev_bid[highestBidder] += bidAmount;
			minBid=bidAmount;
			
			///bidAAmount is mappped to the bidder who will get their refund again
		}

		///highestBidder = msg.sender;
		///bidAmount = msg.value;
		emit HighestBidIncreased(highestBidder,bidAmount);
		
	}

	function withdraw () public returns (bool){

		uint amount = returnPrev_bid[highestBidder];
		if(amount >0){

			returnPrev_bid[highestBidder] = 0;

		///	if (!highestBidder.send(amount)){
				///if amouunt send not equal to "amount" then this performed
		///		returnPrev_bid[highestBidder] = amount;
		///		return false;
		///	}


		}
		return true;

	}

	function auctionEnd() public {


		require (now >= auctionEnd_time);
		require(!ended); ///ended is not called above and not being false

		ended=true;
		emit AuctionEnded(highestBidder, bidAmount);
		///amount transferred to player
	///	player.transfer(bidAmount);
		


	}

	
	



}



