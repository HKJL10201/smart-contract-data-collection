pragma solidity >=0.4.21 <0.6.0;

contract sealedAuction {
	
	//static auction info
	address payable public owner;
	uint256 public escrowAmount;
	uint256 public ipfsHash;
    
    bool public started;
	uint256 public startBlock; 
	
	//timeline
	uint256 public biddingDuration;
	uint256 public revealingDuration;
	uint256 public claimingDuration;

	address public winner;
	bool public winnerSettled;
	uint256 public reservedPrice;
	uint256 public maxRevealedBid;
	uint256 public secondRevealedBid;

	mapping(address => bytes32) public sealedBids;
    mapping(address => uint256) public escrowedFunds;
    mapping(address => uint256) public revealedBids;

    //function() payable { } //fallback function
	constructor(uint256 _ipfsHash, uint256 _escrowAmount, uint256 _biddingDuration, uint256 _revealingDuration,
						   uint256 _claimingDuration, uint _reservedPrice) public
	{
		require(_biddingDuration > 0);
		require(_revealingDuration > 0);
		require(_claimingDuration > 0);
		
        owner = msg.sender;

        ipfsHash = _ipfsHash;
        escrowAmount = _escrowAmount;
        biddingDuration = _biddingDuration;
        revealingDuration = _revealingDuration;
        claimingDuration = _claimingDuration;
        reservedPrice = _reservedPrice;

        started = false;
        maxRevealedBid = 0;
        secondRevealedBid = 0;
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
    	escrowedFunds[msg.sender] += msg.value;
    }
    
    function revealBid(uint256 bid, uint256 salt) public
    	inRevealingPeriod
    {	
    	require(bid >= reservedPrice);
        require(keccak256(abi.encodePacked(keccak256(abi.encodePacked(bid)),keccak256(abi.encodePacked(salt)))) == sealedBids[msg.sender]);
    	revealedBids[msg.sender] = bid;
    	if(bid > maxRevealedBid){
    	    secondRevealedBid = maxRevealedBid;
    		maxRevealedBid = bid;
    		winner = msg.sender;
    	}
    	else if(bid > secondRevealedBid){
    	    secondRevealedBid = bid;
    	}
    }

    function settle() public
    	payable
    	inClaimingPeriod
    	isWinner
    	winnerNotSettled
    {
    	if(escrowedFunds[msg.sender] >= secondRevealedBid){
    		require(msg.sender.send(escrowedFunds[msg.sender] - secondRevealedBid));
    	}
    	if(escrowedFunds[msg.sender] < secondRevealedBid){
    		require(msg.value >= (secondRevealedBid - escrowedFunds[msg.sender]));
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
    	isOwner
    	afterclaimingPeriod
    {
        msg.sender.transfer(address(this).balance);
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
    	require(started && block.number > startBlock && block.number <= startBlock + biddingDuration);
        _;
    }

    modifier inRevealingPeriod {
    	require(started && block.number > startBlock + biddingDuration && block.number <= startBlock +
    			biddingDuration + revealingDuration);
    			_;
    }

    modifier inClaimingPeriod {
    	require(started && block.number > startBlock + biddingDuration + revealingDuration && block.number <= startBlock +
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
   