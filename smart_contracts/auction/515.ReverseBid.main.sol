pragma solidity ^0.8.9;

interface IERC721 {
    function transferFrom(address from, address to, uint Id) external;
}

error invalidBid();

contract dutchAuction {
    address payable public seller;
    IERC721 public immutable nftContract;
    uint public immutable startTime;
    uint public immutable stopTime;
    uint public immutable nftId;
    uint private constant duration = 7 days;
    uint public immutable discRate;
    uint public immutable startingPrice;

    constructor(uint _startingPrice, address nftAddress, uint tokenId, uint _discRate ){
        nftContract = IERC721(nftAddress);
        nftId = tokenId;
        startTime = block.timestamp;
        stopTime = startTime + duration;
        discRate = _discRate;
        seller = payable(msg.sender);
        require(startTime >= discRate * duration, "starting price < min");
        startingPrice= _startingPrice;

    }

    function getPrice() public view returns (uint) {
        uint timeElapsed = block.timestamp - startTime;
        uint discount = discRate * timeElapsed;
        return  startingPrice - discount;
    }

    function buy() public payable{
        require(stopTime>block.timestamp,"Auction finished");
        uint temp = getPrice();

        if(temp>msg.value){
            revert invalidBid();
        }
        uint refund = msg.value - temp;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        nftContract.transferFrom(seller, msg.sender, nftId);
        seller.transfer(address(this).balance);
        selfdestruct(seller);
    }

     function buyAfterAuction() public payable{
        require(stopTime<block.timestamp,"Auction finished");
        uint temp = getPrice();

        if(temp>msg.value){
            revert invalidBid();
        }
        uint refund = msg.value - temp;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        nftContract.transferFrom(seller, msg.sender, nftId);
        seller.transfer(address(this).balance);
        selfdestruct(seller);
    }

}
