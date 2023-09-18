// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Auction.sol";

contract AuctionFactory {
    Auction[] public auctions;
    event ContractCreated(address newContractAddress);

    function createNewAuction(
        address _nft,
        uint256 _nftId,
        uint256 _startingBid,
        uint256 _increment,
        uint256 _duration
    ) public {
        Auction auction = new Auction(
            msg.sender,
            IERC721(_nft),
            _nftId,
            _startingBid,
            _increment,
            _duration
        );
        auctions.push(auction);
        emit ContractCreated(address(auction));
    }

    function getAuctions() external view returns (Auction[] memory _auctions) {
        _auctions = new Auction[](auctions.length);
        for (uint256 i = 0; i < auctions.length; i++) {
            _auctions[i] = auctions[i];
        }
    }
}
