
pragma solidity 0.8.11;

import { Auction } from './Auction.sol';

import "./ERC20.sol";

contract AuctionFactory {
    address[] auctions;
    mapping(address => address[]) active_auctions; // asset_address =&gt; auctions[]
    mapping(address => address[]) complete_auctions; // asset_address =&gt; auctions[]

    event AuctionCreated(address auctionContract, address owner, uint numAuctions, address[] allAuctions);

    address crosAccount;

    modifier onlyCrosAccout {
        require(msg.sender == crosAccount);
        _;
    }

    constructor(address cros_account) public {
            crosAccount =cros_account;
    }

    function initialize(address cros_account) public  {
      crosAccount =cros_account;
  }




    function allAuctions() external view returns (address[] memory) {
        return auctions;
    }

    function publish(address asset, uint256 createdDate, uint256 startTime, uint256 endTime) external returns(address) {
        Auction  newAuction = new Auction(asset, createdDate, startTime, endTime);
        auctions.push(address(newAuction));
        active_auctions[asset].push(address(newAuction));
        return address(newAuction);
    }


}


