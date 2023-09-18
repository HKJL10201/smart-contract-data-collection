//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {EnglishAuction} from "./EnglishAuction.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionFactory is Ownable {
    EnglishAuction[] public deployedAuctions;
    uint256 public ownerFeePool;
    uint256 public immutable creationFee;
    
    event AuctionCreated(address Nft, uint256 NftId, uint256 StartingBid, address Seller, address chosenAuctionToken);
    event FeeWithdrawal(address to, uint256 amount, uint256 time);
 
    constructor(uint256 _creationFee) {
        creationFee = _creationFee;
    }

    function createAuction(address _nft, uint256 _nftId, uint256 _startingBid, address _seller, address _auctionToken) public payable {
        require(msg.value == creationFee, "Factory: You have not provided required fee");
        ownerFeePool += msg.value;
        EnglishAuction newAuction = new EnglishAuction(_nft, _nftId, _startingBid, _seller, _auctionToken);
        deployedAuctions.push(newAuction);
        emit AuctionCreated(_nft, _nftId, _startingBid, _seller, _auctionToken);
    }

    function ownerFeeWithdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= ownerFeePool, "Factory: Can not withdraw more money then available in Fee Pool");
        ownerFeePool -= _amount;
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Factory: Tx has failed try again");
        emit FeeWithdrawal(_to, _amount, block.timestamp);
    }
}