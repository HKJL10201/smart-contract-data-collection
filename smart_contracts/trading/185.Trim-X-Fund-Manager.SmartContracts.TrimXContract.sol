// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
//pragma solidity >= 0.5.0 < 0.6.0;

import "github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/ChainlinkClient.sol";
//import "github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";



contract PortfolioTokens is ChainlinkClient {
    //using SafeMath for uint;                                       // allows us to use SafeMath for certain operations



    //----- Initializing Variables ------------//
address payable private minter;                               // owner's address

// initial amount of each token type
string private our_disclaimer="Your money, your risk!";       // the company disclaimer


//------ Generating Mapping to Display Exchange Rates----------//
mapping (uint=> uint256) public exchange_rates;

//----- Defining the mappping for coin types----------//
mapping (uint => uint256) public baskets;                     // initializing mapping for different coin baskets


//---- Defining the mapping for coin balances for users------//
mapping(address => uint256[3]) balances;                      // Users can have any of the three coins



//---- The is Minter Modifier----------//
modifier isMinter() {
//constructed modifier to ensure that user is the Minter when using specific functions in the constract
    require(msg.sender == minter, "You are not the Coin Minter!");
     _;
}

    

    
    
//------ Parameters needed for the Oracle ----------------//    
    uint256 public price;                                     // price of 1 ETH in USD
    
    address private oracle;                    // oracle ID
    bytes32 private jobId; 
    uint256 private fee;
    
    /**
     * Network: Kovan
     * Oracle: 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e
     * Job ID: 29fa9aa13bf1468788b7cc4a500a45b8
     * Fee: 0.1 LINK
     */
    constructor() public {
        minter=msg.sender;                                             // person who initializes contract becomes owner
        baskets[1]=100000;                                             // Initial Amount of Token1 tokens
        baskets[2]=100000;                                             // Initial Amount of Token2 tokens
        baskets[3]=900;                                                // Initial Amount of Token3 tokens



        //----- Initializing Exchange Rates for Tokens
        exchange_rates[1]=10;                           // Exchange rate for token 1 
        exchange_rates[2]=85;                           // Exchange rate for token 2 
        exchange_rates[3]=100;                           // Exchange rate for token 3
        
        
        //--------- Initializing values for oracle
        setPublicChainlinkToken();                           //set to public network
        oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }
    
    
    
    
//------- Disclaimer -------------//
function CompanyDisclaimer() external view returns (string memory) {
    return our_disclaimer;                                    // returns the company disclaimer
}

    
    

     
     //-------- Calling  the Chainlink Oracle to compute value of tokens
     /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 100 (to remove decimal places from data).
     */
    function CoinValuation() public  returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        //Instantiates a Request from the Chainlink contract
        // request variable is temporarily stored
        
        // Set the URL to perform the GET request on
        //request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=USD&tsyms=ETH");
        request.add("get", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD");
        request.add("path", "USD");
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 100;
        request.addInt("times", timesAmount);
        
        // Sends the request with specified oracle, constructed request and fee 
        // returns the ID of the request
        // used in process to make sure only that the address you want can call your Chainlink callback function.
        //but allows the target oracle to be specified. It requires an address, a Request, and an amount, and returns the requestId
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
     //Used on fulfillment callbacks to ensure that the caller and requestId are valid.
    function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId)
    {
        price = _price;      // price of 1 ETH in USD
        uint ratio =1+(300000/price);                      // tells us how many ETH our portfolio is worth
        exchange_rates[1]=10*ratio;                           // Update of Exchange rate for token 1 
        exchange_rates[2]=85*ratio;                           // Update of Exchange rate for token 2 
        exchange_rates[3]=100*ratio;                           // Update of Exchange rate for token 3
        
        
    }
    
    
  //----------- CoinMinter function-------------//
// function that mints tokens. If amount of tokens are at or
// below threshold, then more coins are minted
// where only the owner will mint tokens
function CoinMinter ()  isMinter public  {
    for (uint i=1; i<4; i++){
        if (baskets[i]<=1000) {
        baskets[i]=baskets[i]+10000;                                                                  // mint 9000 more tokens for basket i=1,2,3
        }
    }
}  
    
   
   
  
//----------- Withdraw function -----------------//
// deposits money to owner's/minter's wallet 
function  withdraw(uint _amount) isMinter public returns(uint){
    require(_amount<=address(this).balance,"Amount requested exceeds balance of contract!");              // ensures amount to withdraw is no more than balance of contract
    msg.sender.transfer(address(this).balance);                                                           // Transfer of funds to minter's wallet
    
    return address(this).balance;                                                                         // returns the balance of the contract
} 
    
    
    
    
    
 //--------- Function for User to Purchase coins------------//
// user will specify a token type, as well as an amount (no more than 100)
function coin_purchase  (uint token_type, uint amount_of_tokens) public payable {
    // limitation on number of tokens to Purchase
    require(amount_of_tokens <= 100, "You have exceeded the maximum number of tokens");
    
    // also token_type must be 1,2, or 3
    require(token_type<=3 && token_type>=1, "Please select a valid token type; must be 1,2, or 3");
    
    // ensures you have enough money for requested number of coins
    //require(msg.value>=amount_of_tokens/exchange_rates[token_type],"Note enough ETH to purchase requested number of tokens");
    
    
// Transfer coins when conditions are met
    // sending users their specified number of tokens for selected type
    balances[msg.sender][token_type-1]=balances[msg.sender][token_type-1]+amount_of_tokens;
    baskets[token_type]=baskets[token_type]-amount_of_tokens;                                // updating available token amounts
    uint rem=msg.value-amount_of_tokens*exchange_rates[token_type];
    
    //---Sends Remaining amount back to user------//
    if (rem>0){
        msg.sender.transfer(rem);
    }
}
   
    
//------- Check Contract Balance Function (Work in Progress) ----------//
// allows minter to check the contract balance
function CheckContractBalance() isMinter public view returns(uint) {
        return address(this).balance;
}



//---------- Fallback function    ---------//
//-----allows funds to be deposited to the account  -------//
receive() external payable{
    
}



 
//-----End of Contract  ----------//    
}