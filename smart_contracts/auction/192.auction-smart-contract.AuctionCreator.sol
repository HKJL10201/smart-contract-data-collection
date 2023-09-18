pragma solidity ^0.5.0;

/**
 * @title Auction creator
 * @dev Create an instance of Auction Contract 
 */

import "./Auction.sol";


contract AuctionCreator {
    address[] public auctionList;

    /**
    * @dev load a new instance of Auction.
    *      _noOfDaysTorun = number of days that Auction will run
    */
    function CreateAuctionInstance(uint _noOfDaysTorun) public {
        Auction newInstance = new Auction(msg.sender, _noOfDaysTorun);
        auctionList.push(address(newInstance));
    }
}
