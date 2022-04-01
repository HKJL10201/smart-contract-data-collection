pragma solidity ^0.7.0;

import "./VoteDappTokenV3.sol";

import "./SafeMath.sol";

contract VoteDappTokenSale {
    
    using SafeMath for uint256;
    
    address admin;
    VoteDappToken tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);
    
    event Return(address _buyer, uint256 _amount);

    //cost is 1000000000000000 wei

    constructor(uint256 _tokenPrice) {
        admin = msg.sender;
        
        tokenContract = new VoteDappToken(21000000);
        
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 amount) external payable {
        require(msg.value == amount.mul(tokenPrice), "You did not send the correct amount of ether.");
        require(tokenContract.balanceOf(address(this)) >= amount, "No more tokens to go around.");
        require(tokenContract.transfer(msg.sender, amount), "Failed to send tokens.");

        tokensSold += amount;

        Sell(msg.sender, amount);
    }
    
    
    //returns contract address
    function getContractAddr() external view returns (address) {
        return address(tokenContract);
    }
    
}
