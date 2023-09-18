// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";


//---- Initializing the Contract----------//
contract PortfolioTokens {
using SafeMath for uint;                                       // allows us to use SafeMath for certain operations

//----- Initializing Variables ------------//
address payable private minter;                               // owner's address

// initial amount of each token type
string private our_disclaimer="Your money, your risk!";       // the company disclaimer


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


// Initializing owner/minter  of constract upon Deployment
constructor () public { 
minter=msg.sender;                                            // person who initializes contract becomes owner
baskets[0]=10000;                                             // Initial Amount of Token1 tokens
baskets[1]=10000;                                             // Initial Amount of Token2 tokens
baskets[2]=10000;                                             // Initial Amount of Token3 tokens
} 



//------- Disclaimer -------------//
function CompanyDisclaimer() external view returns (string memory) {
    return our_disclaimer;                                    // returns the company disclaimer
}


// ----------Coin Valuation function------------//
// computes value of each coin using value of portfolio
function CoinValuation  () private {
    
//calling oracle from ChainLink to get balancen of portfolio
}



//----------- CoinMinter function-------------//
// function that mints tokens. If amount of tokens are at or
// below threshold, then more coins are minted
// where only the owner will mint tokens
function CoinMinter ()  isMinter public  {
    for (uint i=1; i<4; i++){
        if (baskets[i]<=1000) {
        baskets[i]=baskets[i].add(9000);                           // mint 9000 more tokens for basket i=1,2,3
        }
    }
//return minter;  ideally, return basket number with new amount of tokens
}



//----------- Deposit function -----------------//
// deposits money to owner's/minter's wallet 
function  withdraw() isMinter public returns(uint){
    msg.sender.transfer(address(this).balance);               // Transfer of funds to minter's wallet
    return address(this).balance;
}



//--------- Function for User to Purchase coins------------//
// user will specify a token type, as well as an amount (no more than 100)
function coin_purchase  (uint token_type, uint amount_of_tokens) public {
    // limitation on number of tokens to Purchase
    require(amount_of_tokens <= 100, "You have exceeded the maximum number of tokens");
    
    // also token_type must be 1,2, or 3
    require(token_type<=3 && token_type>=1, "Please select a valid token type; must be 1,2, or 3");


    
    
// Transfer coins when conditions are met
    // sending users their specified number of tokens for selected type
    balances[msg.sender][token_type-1]=balances[msg.sender][token_type-1].add(amount_of_tokens);
    baskets[token_type]=baskets[token_type].sub(amount_of_tokens); // updating available token amounts
}



//------- Check My Balance Function (Work in Progress) ----------//
// allows user to check coin balance of each type
//function CheckMyBalance() public view returns(uint256[3]) {
//        return balances[msg.sender];
//}



}