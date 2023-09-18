import "./asset contract.sol";
contract auction{
    
    //Declaration of the variables
    address owner;
    address payable public beneficiary;
    address public highestBidder;
    uint public highestBid=0;
    uint public auctionStartTime;
    uint public auctionEndTime;
    assetContract assetContractAddress;
    uint tokenId;
    
    //Creation of the modifier
    modifier onlyOwner{
        
        //Require statement
        require(msg.sender == owner ,"Only Owner can create and deploy this Function");
        _;
    }

    //Creation of the mapping
    mapping(address => uint) pending_returns;

    //Creation of the event
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    //Creation of the constructor
    constructor(address payable _beneficiary,assetContract _assetContract,uint _biddingTime,uint _tokenId) {
        
        owner = msg.sender;
        beneficiary = _beneficiary;
        auctionStartTime = block.timestamp;
        auctionEndTime = block.timestamp + _biddingTime;
        assetContractAddress = _assetContract;
        tokenId = _tokenId;
       }
    
    //Defining of the function
    function bid() public payable{
          
        //Require condition
        require(msg.value > highestBid,"There is already a higher bid !!! Please bid higher than preivous bid");
        require(block.timestamp < auctionEndTime,"Auction has been ended!!!Bye Bye have a good day ahead...");

        //If condition
        if (highestBid != 0) {
            
            pending_returns[highestBidder] += highestBid;
        }
        
        //Copying msg.sender and msg.value into variables highestBidder and highestBid
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        //Emittion of the event
        emit HighestBidIncreased(msg.sender, msg.value);
    }
    
    //Defining of the function
    function withdraw() public returns(bool){
        
        //Copying data from one datatype to another datatype
        uint amount = pending_returns[msg.sender];
        
        //Require statement
        require(block.timestamp > auctionEndTime,"Auction has not been ended yet!!! You cannot withdraw your bidding amounts before auction ends");
        require(msg.sender != highestBidder,"Highest Bidder can't withdraw its bidding amount");
        require(amount > 0,"Only Valid Bidders can withdraw their Bidding amounts");
        
        //If condition
        if (amount > 0) {
            
            //This is set to 0 because the user will call this function again as a part of the receiving call before the withdraw function returns anything.
            //For eg.1 Case:- By default pending_returns will be 0 if suppose user bids 1 ether then it will set 1 ether but after withdraw function call it will again set to 0, in this user will not get confused about his/her balances in pending_returns.
            //       2 Case:- If pending_returns is set to 1 by default and if suppose user bids 1 ether then it set to 1000000000000000001 eher but after withdraw function it will again set to 1, in this user will get confused that his/her balances is still remaining in the pending_returns.
            pending_returns[msg.sender] = 0;

             if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                pending_returns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    //Defining of the function
    function auctionend() public onlyOwner{
        
        //Copying the data from one datatype to another datatype
        uint amount = pending_returns[msg.sender];
        
        //Require statement
        require(block.timestamp > auctionEndTime,"Auction has not been ended yet!!!");
        
        //If else condition
        (bool success,)=payable(beneficiary).call("");
        if(success){
            assetContractAddress.transferFrom(msg.sender,highestBidder,tokenId);
        }else{
            pending_returns[highestBidder]=amount;
        }
        require(success);
        
        //Emition of the event
        emit AuctionEnded(highestBidder, highestBid);
        
        //Transfering the highestBid amount of highestBidder to a beneficiary wallet
        beneficiary.transfer(highestBid);
    }
}
