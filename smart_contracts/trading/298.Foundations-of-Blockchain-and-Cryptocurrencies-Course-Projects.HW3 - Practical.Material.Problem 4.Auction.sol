pragma solidity ^ 0.5.1;


contract Auction {

    struct Description {
        uint deployBlock;
        address payable admin;
        uint startBlock;
        address payable winnerAddress;
        uint winnerBid;
    }

    Description public description;

    modifier onlyAdmin() {
        require(msg.sender == description.admin);
        _;
    }

    event auctionStarted();
    event auctionFinished(address winnerAddress, uint winnerBid);

    function activateAuction() public;
    function finalize() public;
}