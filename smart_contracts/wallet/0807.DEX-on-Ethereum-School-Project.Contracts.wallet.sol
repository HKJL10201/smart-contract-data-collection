pragma solidity >=0.6.0 <0.8.0;

//We can import a file (IERC20.sol) which is used as an interface for ERC20 tokens, 
//with the function headers, etc. that we can use with our dex. 
//We need this interface. We can use it with the information in our struct, 
//to interact with token contracts, and we can use it for functions like withdraw()
//(It is located in @OpenZeppelin\contracts\token\ERC20\IERC20.sol)

import '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
//We also import SafeMath
import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
//By adding the Ownable file, there is a limit on what users can do with the contract,
//for example, only the contract owner can add new tokens to the contract. 
import '../node_modules/@openzeppelin/contracts/math/SafeMath.sol';

contract Wallet is Ownable {
    using SafeMath for uint256;
//We make a struct to store information about the tokens used in our DEX.
//For tokens traded/bought in the DEX, we need token addresses, 
//to call the token contracts, to do transfer calls.
    struct Token {
    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }
    
    mapping(bytes32 => Token) public tokenMapping;
    //We save the token address & tickers in a combined array & mapping

//bytes32[] is an array
//Here are all the tickers of the tokens bought or traded in this DEX,
//which are used as token IDs in this DEX, 
//and they need to be unique.
//These bytes32 ticker items are put into a mapping, in which the ticker points to the struct called "Token",
//which contains the ticker and the token address. 
//With this data storage structure, we have an array that we can use to loop through, 
//for example to get information about a particular item in a group of items,
//and with the mapping, we have a way to quickly get information, and also to update an item, 
//by using a particular key and its connected value.
//With this structure, we cannot delete items, but a delete structure can be added.
//This struck & mapping has information about tokens, the mapping below has information about balances.
    bytes32[] public tokenList;
    
//double mapping for multiple balances of ETH and ERC20 tokens.
//bytes32 is a data type used for the crypto ticker.
//The address points to another mapping, 
//of the ticker/token symbol (bytes32) that points to an integer (uint256)
    mapping(address => mapping(bytes32 => uint256)) public balances;
    
    
//This function adds token information to our storage
//It is external, since we do not need to run it from within here, also, this way we can save gas expenses
//we save it to our tokenMapping, for the ticker, connected with the struct with the name "Token", 
//which has a ticker symbol & a token contract address
//and we add it to the tokenList array, to which we only add / push the ticker (not the token)
//for a list of all of the IDs. 
//CHECK IF I WROTE "TICKER" IN A PLACE WHERE IT SHOLD BE "TOKEN NAME" !!
//the onlyOwner modifier limits the act of adding a token to the contract owner.
//to do this, the teacher put onlyOwner in the heading, before external, but this was shown as an error,
//which could stop compiling of the contract.
    function addToken(bytes32 ticker,address tokenAddress) onlyOwner external {
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }
  
  
//DEPOSIT 
//In this function, there is a deposit from user into this dex contract, 
//calling the token contract, to transfer from msg.sender to this dex contract
//with ERC20 tokens, there is a tranderFrom function
//Something in the deposit function that is different from the withdraw function is that we ask
//the ERC20 contract to transferFrom msg.sender to address(this) which is us / the dex contract address
//the user has already stated an amount to transfer, before using this contract, and
//this the IERC20(tokens)... instruction will throw an error if the amount of the transfer is not real.
// the require(tokenMapping[ticker]... instruction checks if the token in the deposit exists in our dex.
//this instruction is used mnultiple time, and can be replaced by a modifier:
//  modifier tokenExist(bytes32 ticker){
    //  require(tokenMapping[ticker].tokenAddress != address(0), "Token does not exist"); REQUIRE + ERROR MESSAGE
    //  _;  }
    // Then we can use the modifier tokenExist(ticker) in funcion headers, before the visibility keyword
    function deposit(uint amount,  bytes32 ticker) tokenExist(ticker) external {
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
        balances[msg.sender][ticker] = balances[msg.sender][ticker].add(amount);
    }
    
    
//withdraw function has interaction with the token contract, 
//to transfer token ownership between users and our contract, 
//we need to interact with the ERC20 token contract
//we use the the IERC20 interface instruction, and the IERC20.sol file, to interact with the token contract.
//in the IERC20 instruction, we need to input the address, using tokenMapping for the ticker, 
// .tokenAddress, 
//and we do a transfer call with .transfer() this is a transfer from us, 
//so that's why we can do the transfer call,
//sent to the msg.sender, from this contract to msg.sender, which is the owner of the tokens 
//The dex just keeps/stores the tokens owned by users, and they can withdraw the tokens that they own
//we send tokens back to the owners, we transfer from us to them, with the amount
//We also need to change the balance of the msg.sender, and the ticker, we need to reduce the amount of this
//we use Safemath for this, to be safe.
// "sub" means "subtract"
//we subtract the amount, with .sub(amount) 
// There was a problem with using .sub, 
//until I imported SafeMath and added instruction: using SafeMath for uint256; 
//If I get rid of SafeMath, I might need to change the .sub instruction.
//Before withdraw, we check that the user has the avaiable amount to withdraw.
//We do this with require that balances[msg.sender][ticker] >= amount.
//If not, we throw an error: "Balance not sufficient".
//We also need to check that the token is a real token in this dex, which we do with require
//tokenMapping for the ticker . tokenAddress is not equal to the zero address, which is address(0).
//We check with the zero address because 
//if this mapping for a particular ticker points to a struct which has not been made,
//the values will be zero, including both the ticker and the address
//When an address is zero or not made/started in the dex, 
//it is a zero address, "0x0000000000000000000000" which is also written "address(0)".
//Frst we check that the token is a real one on the dex, then we check about amount.
    function withdraw(uint amount, bytes32 ticker) tokenExist(ticker) external {
        require(balances[msg.sender][ticker] >= amount,'Insuffient balance'); 
        balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(amount);
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
    }
    function depositEth() payable external {
        balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].add(msg.value);
    }
    
    function withdrawEth(uint amount) external {
        require(balances[msg.sender][bytes32("ETH")] >= amount,'Insuffient balance'); 
        balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].sub(amount);
        msg.sender.call{value:amount}("");
    }
    
    modifier tokenExist(bytes32 ticker) {
        require(tokenMapping[ticker].tokenAddress != address(0), 'token does not exist');
        _;
    }
}
