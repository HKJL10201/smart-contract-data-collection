// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract DutchAuction  {

    uint32 private immutable DURATION = 90 days ;

    address payable private _owner;
    uint private _startingPrice;

    IERC721 private _nft;
    uint private _nftId;

    uint32 _startAt;
    uint32 _expiresAt;

    bool private _started ;
    bool private _ended;

    uint private _discountRate;

    constructor(
       address nft_,
       uint nftId_,
       uint discountRate_,
       uint startingPrice_
    ){
        _owner = payable(msg.sender);
        _nft = IERC721(nft_);
        _nftId = nftId_;

        _startAt = uint32(block.timestamp);
        _expiresAt = _startAt + DURATION;

        require(startingPrice_ > 0 , "price < 0" );
        _startingPrice  = startingPrice_;
        require(discountRate_ > 0 , "rate < 0");
        _discountRate = discountRate_;

        _started = true;
    }

    function getCurrentPrice() public view returns (uint) {
        uint timeElapsed = _startAt - block.timestamp;
        uint discount = timeElapsed * _discountRate;
        return _startingPrice - discount;
    }

    function buy() external  payable {
        require(msg.sender != address(0) , "invalid address");
        require(_started , "not started");
        require(block.timestamp < _expiresAt  , "ended");
        _ended = true;
        uint price = getCurrentPrice();
        require(msg.value >= price , "value < price");
        uint refund = msg.value - price;
        if(refund > 0){
        payable(msg.sender).transfer(refund);
        }

        _nft.transferFrom(_owner , msg.sender, _nftId);
        _owner.transfer(msg.value);

        selfdestruct(_owner);
    }

}