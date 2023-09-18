//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma abicoder v2;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ERC20Tokens {

////////////////////////////Global Variables & Mappings///////////////////////////
     address[] owners;
    string[] public tokenList;
     uint256 public depositId = 0;
    uint256 public withdrawalId = 0;

    mapping(address => mapping(string => uint)) public balances;
    mapping(string => Token) public tokenMapping;
 



    struct Token {
        string ticker;
        address tokenAddress;
    }
    
    
////////////////////////////Modifiers///////////////////////////

    modifier onlyOwners(){
        bool owner = false;
        for(uint i=0; i<owners.length;i++){
            if(owners[i] == msg.sender){
                owner = true;
            }
        }
        require(owner == true);
        _;
    }

    modifier tokenExists(string memory ticker) {
        
         if(keccak256(bytes(ticker)) != keccak256(bytes("ETH"))) {
            
            require(tokenMapping[ticker].tokenAddress != address(0), "Token does not exist");
         }
         _;
    }
    

////////////////////////////Events///////////////////////////

    event fundsDeposited(string ticker, address from, uint256 id, uint amount, uint256 timeStamp);
    event fundsWithdrawed(string ticker, address from, uint256 id, uint amount, uint256 timeStamp);
   
    
    function addToken(string memory ticker, address tokenAddress) external onlyOwners {

        for(uint i = 0; i < tokenList.length; i++) {
            if(keccak256(bytes(tokenList[i])) == keccak256(bytes(ticker))) {
                revert("Token already added");
            }
        }
        
        require(keccak256(bytes(ERC20(tokenAddress).symbol())) == keccak256(bytes(ticker)));
        
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        //add the new token to the token list
        tokenList.push(ticker);
    }
    



    function depositERC20Token(uint amount, string memory ticker) external onlyOwners tokenExists(ticker) returns(bool _success){

        require(tokenMapping[ticker].tokenAddress != address(0));
    
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
        balances[msg.sender][ticker] += amount;  
        _success = true;
        //emit deposited(msg.sender, address(this), amount, ticker);
        emit fundsDeposited(ticker, msg.sender, depositId, amount, block.timestamp);
        depositId++;

        return _success;
    }

  

    //withdrawal function
    function withdrawERC20Token(uint amount, string memory ticker) external tokenExists(ticker) onlyOwners {
        require(tokenMapping[ticker].tokenAddress != address(0));
        require(balances[msg.sender][ticker] >= amount);

        balances[msg.sender][ticker] -= amount;
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
        emit fundsWithdrawed(ticker, msg.sender, withdrawalId, amount, block.timestamp);
        withdrawalId++;

    }

        
    function getTokenList() public view returns (string[] memory) {
        
        return tokenList;
    }
    
    function getTicker(address tokenAddress) public view returns (string memory) {
        
        require(tokenAddress != address(0));
        return ERC20(tokenAddress).symbol();
    }
}






