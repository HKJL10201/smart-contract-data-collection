pragma solidity >=0.4.21 <0.6.0;

contract sealedAuction {
	
	//static auction info
	address public owner;
	uint256 public escrowAmount;
	uint256 public ipfsHash;

	//timeline
	uint256 public biddingDuration;
	uint256 public revealingDuration;
	uint256 public claimingDuration;

	bool public started;
	uint256 public startBlock; 

	address public winner;
	bool public winnerSettled;
	uint256 public maxRevealedBid;

	mapping(address => bytes32) public sealedBids;
    mapping(address => uint256) public escrowedFunds;
    mapping(address => uint256) public revealedBids;

    //function() payable { } //fallback function
	constructor(uint256 _ipfsHash, uint256 _escrowAmount, uint256 _biddingDuration, uint256 _revealingDuration,
						   uint256 _claimingDuration) public
	{
		require(_escrowAmount > 0);
		require(_biddingDuration > 0);
		require(_revealingDuration > 0);
		require(_claimingDuration > 0);

        owner = msg.sender;

        ipfsHash = _ipfsHash;
        escrowAmount = _escrowAmount;
        biddingDuration = _biddingDuration;
        revealingDuration = _revealingDuration;
        claimingDuration = _claimingDuration;

        started = false;
        maxRevealedBid = 0;
        winnerSettled = false;
    }

    function startAuction() public
    	isOwner
    	notStarted
    {
    	startBlock = block.number;
    	started = true;
    	//emit auctionStarted(startBlock, biddingDuration);
    }

    //event auctionStarted(uint256 startBlock, uint256 biddingDuration);

    function placeBid(bytes32 bid) public 
    	payable
    	isNotOwner
    	inBiddingPeriod
    	sufficientEscrow
    {
    	sealedBids[msg.sender] = bid;
    	escrowedFunds[msg.sender] = msg.value;
    }

    function revealBid(uint256 bid, uint256 salt) public
    	inRevealingPeriod
    {	
    	require(bid > 0);
    	require(keccak256(abi.encodePacked(bid,salt)) == sealedBids[msg.sender]);
    	revealedBids[msg.sender] = bid;
    	if(bid > maxRevealedBid){
    		maxRevealedBid = bid;
    		winner = msg.sender;
    	}
    }


    function settle() public
    	payable
    	inClaimingPeriod
    	isWinner
    	winnerNotSettled
    {
    	if(escrowedFunds[msg.sender] > maxRevealedBid){
    		require(msg.sender.send(escrowedFunds[msg.sender] - maxRevealedBid));
    	}
    	if(escrowedFunds[msg.sender] < maxRevealedBid){
    		require(msg.value >= maxRevealedBid - escrowedFunds[msg.sender]);
    	}
    	winnerSettled = true;
    }

    function refund() public
    	inClaimingPeriod
    	isNotWinner
    	hasValidBid
    	hasEscrowedFunds
    {
    	require(msg.sender.send(escrowedFunds[msg.sender]));
    	escrowedFunds[msg.sender] = 0;
    }

    function closeAuction() public 
        payable
    	isOwner
    	afterclaimingPeriod
    {
        //selfdestruct(owner);
    }

 	modifier isOwner {
    	require(msg.sender == owner);
    	_;
    }

    modifier isNotOwner {
    	require(msg.sender != owner);
    	_;
    }

    modifier notStarted {
    	require(!started);
    	_;
    }

    modifier inBiddingPeriod {
    	require(started && block.number > startBlock && block.number < startBlock + biddingDuration);
        _;
    }

    modifier inRevealingPeriod {
    	require(started && block.number > startBlock + biddingDuration && block.number < startBlock +
    			biddingDuration + revealingDuration);
    			_;
    }

    modifier inClaimingPeriod {
    	require(started && block.number > startBlock + biddingDuration + revealingDuration && block.number < startBlock +
    			biddingDuration + revealingDuration + claimingDuration);
        _;
    }

    modifier afterclaimingPeriod {
    	require(started && block.number > startBlock +
    			biddingDuration + revealingDuration + claimingDuration);
        _;
    }

    modifier sufficientEscrow {
    	require(msg.value >= escrowAmount);
    	_;
    }

    modifier isWinner {
    	require(msg.sender == winner);
    	_;
    }

    modifier isNotWinner {
    	require(msg.sender != winner);
    	_;
    }

    modifier hasValidBid {
    	require(revealedBids[msg.sender] != 0);
    	_;
    }

    modifier hasEscrowedFunds {
    	require(escrowedFunds[msg.sender] > 0);
    	_;
    }

    modifier winnerNotSettled {
    	require(!winnerSettled);
    	_;
    }
    
}
/*
clean(id)
		}
	}
	function clean(uint id) private{
		auction a = Auctions[id];
		a.highestBid = 0;
		a.highestBidder =0;
		a.deadline = 0;
		a.recipient = 0;
		a.bidHash = 0;
	}
}

function cancelAuction()
    onlyOwner
    onlyBeforeEnd
    onlyNotCanceled
    returns (bool success)
{
    canceled = true;
    LogCanceled();
    return true;
}

*/