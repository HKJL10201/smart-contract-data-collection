pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/token/StandardToken.sol";

contract ShopToken is StandardToken {
    // ERC20 Metadata
    string public name = "SHOP Token";
    string public symbol = "SHOP";
    uint8 public decimals = 18;
    uint private multiplier = 10 ** uint(decimals);

    // Constructor
    // @param _auctionAddress Auction smart contract address
    // @param _initialSupply Initial token unit supply
    // @param _auctionSupply Auction supply in token units
    function ShopToken( 
        address _auctionAddress,
        uint _initialSupply,
        uint _auctionSupply) 
        public 
    {
        // Input parameters validation
        require(_auctionAddress != 0x0);
        require(_initialSupply > multiplier);
        require(_auctionSupply < _initialSupply);

        // Set `totalSupply` value for `ERC20Basic` interface
        totalSupply = _initialSupply;

        // Transfer all tokens to smart contract creator
        balances[msg.sender] = _initialSupply;

        // Transfer some tokens for first dutch auction
        transfer(_auctionAddress, _auctionSupply);
    }
}