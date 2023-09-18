// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IBlindAuction {

    function createBlindAuction(uint _biddingTime, uint _revealTime, address payable _nftContractAddress,address payable _ownerAddress, uint256 _tokenId, uint256 _initialPrice) external;
    
    function blind_my_bid(uint _value, bool _fake, bytes32 _secret) external pure returns (bytes32);

    function bid(bytes32 _blindedBid) external payable;

    function reveal(uint[] calldata _values, bool[] calldata _fakes, bytes32[] calldata _secrets) external;

    function withdraw() external;

    function auctionEnd() external;

    function placeBid(address _bidder, uint _value) external returns(bool success);

    function claimNFT() external;

    function getBidderCount(address bidder) external view returns (uint256);

    function getBidderAddress(uint256 index) external view returns (address);
}
