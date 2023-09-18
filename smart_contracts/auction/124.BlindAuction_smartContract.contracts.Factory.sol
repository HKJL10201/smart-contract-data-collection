// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import { IBlindAuction } from "./IBlindAuction.sol";
import { NFTBlindAuction } from "./BlindAuction.sol";
 
contract NFTBlindAuctionFactory {

    NFTBlindAuction[] public _blindauctions;

    event AuctionCreated(address indexed auction, address indexed owner);   

    function createBlindAuction(uint _biddingTime, uint _revealTime, address payable _nftContractAddress,address _ownerAddress, uint256 _tokenId, uint256 _initialPrice) public returns (NFTBlindAuction newBlindAuction) {
        newBlindAuction = new NFTBlindAuction(_biddingTime, _revealTime, _nftContractAddress, _ownerAddress, _tokenId, _initialPrice);
        _blindauctions.push(newBlindAuction);

        emit AuctionCreated(address(newBlindAuction), msg.sender);
    }

    function getAuctionCount() external view returns (uint256) {
        return _blindauctions.length;
    }

} 