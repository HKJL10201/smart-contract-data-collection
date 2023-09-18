pragma solidity 0.8.10;

interface IERC721{

    function transfer(address,uint) external;

    function transferFrom(
        address,
        address,
        uint
    )external;
}

contract Auction{

    event Start();
    event End(address highestBidder , uint highestBid);
    event Bid(address indexed sender ,uint amount);
    event Withdraw(address indexed bidder,uint amount);


    address payable public seller ; ///we have to pay the profits from highest bidder to seller

    bool public started;
    bool public ended;
    uint public endAt;

    IERC721 public nft;
    uint public nftId; ///unique id of the NFT that we want to auction

    uint public highestBid;
    address public highestBidder;

    mapping( address =>uint ) public bids;

    constructor (){

        seller = payable(msg.sender); ///it will be set when the contract is deployed

    }

    function start(IERC721 _nft,uint _nftId,uint startingBid) external { ///external then we can call from outside the smart contract

        require(!started,"Already started!");
        require(msg.sender==seller, "You did not start the auction");

        highestBid = startingBid;
        
        nft = _nft;
        nftId = _nftId;

        ///auction will get started if the the person owning the NFT starts the auction
        nft.transferFrom(msg.sender , address(this),nftId ); 

        started = true;
        endAt = block.timestamp + 2 days;


        emit Start(); ///event emitted signifying auction has started



    }

    function withdraw() external payable {

        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;

        (bool sent ,bytes memory data) = payable(msg.sender).call{value : bal}("");
        require(sent,"Could not withdrarw"); ///if any issues while withdrawing

        emit Withdraw(msg.sender , bal);




    }
    function bid() external payable{

        require(started,"Not started");
        require(block.timestamp < endAt , "Ended!");

        require(msg.value > highestBid);

        if(highestBidder!= address(0)) { ///address(0) is the default address or the first person to make a bid

            bids[highestBidder] +=highestBid;

        }
        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(highestBidder,highestBid);
    }
    function end() external {

        require(started,"You need to start first");
        require(block.timestamp >=endAt , "Auction is still ongoing");
        require(!ended ,"Auction already ended");

        if(highestBidder!=address(0)){ ///if address(0) then no one bid for the NFT

            nft.transfer(highestBidder,nftId);
            ///pay the amount to seller

            (bool sent, bytes memory data ) = seller.call{value:highestBid}("");
            require(sent,"Could not pay the seller");

        }else {
            ///if no body bid
            nft.transfer(seller,nftId);


        }
        ended = true;
        emit End(highestBidder ,highestBid);
    }
}