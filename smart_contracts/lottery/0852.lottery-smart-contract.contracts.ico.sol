pragma solidity 0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
constructor() public ERC20("Nations Combat","NCT") {
_mint(msg.sender,50000000*10**18);
}

}
contract TokenICO {
address admin;
Token public tokenContract;
uint256 public tokenPrice;
uint256 public tokensSold;

event Sell(address _buyer, uint256 _amount);

function TokenSale(Token _tokenContract, uint256 _tokenPrice) public {
admin = msg.sender;
tokenContract = _tokenContract;
tokenPrice = _tokenPrice;
}

function multiply(uint x, uint y) internal pure returns (uint z) {
require(y == 0 || (z = x * y) / y == x);
}

function buyTokens(uint256 _numberOfTokens) public payable {
require(msg.value == multiply(_numberOfTokens, tokenPrice));
require(tokenContract.balanceOf(address(this)) >= _numberOfTokens*10**18);
require(tokenContract.transfer(msg.sender, _numberOfTokens*10**18));

tokensSold += _numberOfTokens;

Sell(msg.sender, _numberOfTokens);
}

function endSale() public {
require(msg.sender == admin);
require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));

// UPDATE: Let's not destroy the contract here
// Just transfer the balance to the admin
payable(admin).transfer(address(this).balance);
}
}

