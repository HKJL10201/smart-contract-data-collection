pragma solidity ^0.4.0;
//pragma experimental ABIEncoderV2;
contract Auction
{

    event Print(string _name, address _value);
    event Print1(string _name, uint _value);
    uint startTime;
    uint endTime;
    uint q=0;
    uint M=0;
    
    uint notaryCount =0 ;
    
    //address of auctioneer
    address autioneerAddress ;

    address []  notaryAddress ;
    address []  registeredBiddersAddress ;
    uint    []  notaryPayment ; 
    mapping (address => uint) bidderMap ;
    mapping (address => uint)  submittedBidders ;
    mapping (address => uint)  notaryMap;

    Bidders[] winners;
    uint[] payments;
    
    struct Notaries
    {
        address myAddress ;
    }

    struct Pair
    {
        uint u ;
        uint v ;
    }

    struct Bidders
    {
        Pair w  ;
        // set of items
        Pair[] bidderChoice ;
        
        uint itemLength;

        uint assignedNotary ;
        address thisBiddersAddress ;

    }

    // array of Bidders
    Bidders[] biddersList ;
    Bidders[]  L ;
    Bidders[]  R ;



    //acutioneer will invoke the constructor
    constructor ( uint _q , uint _M ) public payable
    {
        q = _q ;
        M = _M ;
        startTime = now; // in seconds
        endTime = now + 60;
        autioneerAddress = msg.sender;
    }

    function getQM() view public
    returns (uint ,uint )
    {
        return( q , M );
    }
    
    modifier onlyAfter (uint _time) {require(now > _time, "Too early"); _;}
    
    //check not auctioneer
    modifier notAuctioneer()
    {
        require (msg.sender != autioneerAddress , "Call by auctioneer not permitted");
        _;
    }
    
    modifier checkIfSufficientNotaries()
    {
        require ( notaryCount > biddersList.length , "Number of Notaries not sufficient");
        _;
    }

    //check not Bidder
    modifier notBidder()
    {
        require (bidderMap[msg.sender] != 1 , "Call by bidder not permitted");
        _;
    }

    //check not Notary
    modifier notNotary()
    {
        require (notaryMap[msg.sender] != 1 , "Call by Notary not permitted");
        _;
    }

    //check wheather already submitted bid
    modifier notSubmittedBid()
    {
        require ( submittedBidders[msg.sender] !=1 , "Bid already submitted");
        _;
    }

    // check wheather values given by bidder are correct
    modifier checkValidValues(uint[] U , uint[] V)
    {
        require( ((U.length == V.length ) && validateValues(U , V)==true) , "Either length not equal or invalid values"  );
        _;
    }
    

}