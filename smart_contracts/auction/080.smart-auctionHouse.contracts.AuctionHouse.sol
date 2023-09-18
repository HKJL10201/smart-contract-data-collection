//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";


contract AuctionHouse {

    uint256 countTotalAuctionsDeployed = 0;

    struct Auction {
        address payable owner;
        uint256 createTimestamp;
        uint256 endTimestamp;
        uint256 startBid;
        uint256 currentBid;
        string ownerWithdrawSecret;
    }

    //event newAuction(Auction[] auctions);


    event newAuction( mapping( address => Auction ) auctions );
    
    constructor() {
    }


    function addAuction (uint256 startBidMin, string ownerSecret) payable external returns ( Auction ) {
        countTotalAuctionsDeployed += 1;

        auctions[msg.sender] = new Auction(
            msg.sender,
            block.timestamp,
            block.timestamp * 1 days,
            startBidMin,
            startBidMin,
            ownerSecret
        );

        emit newAuction(auctions);

        return auctions[msg.sender];
    }

    function bid(uint256 amount, address payable ownerAuction) payable external returns ( boolean ) {
        require(auctions[ownerAuction], "Auction not exist for this address");

        require(block.timestamp > auctions[ownerAuction].endTimestamp, "Auction is over");


        uint256 memory currentOld = auctions[ownerAuction].currentBid;

        require(amount < currentOld, "Bid is too low");

        // todo transfer

        auctions[ownerAuction].currentBid = amount;

        return true;
    } 

    function withdraw (string secret) payable external returns ( uint256 ) {
        require(auctions[msg.sender], "Auction not exist for your address");
        require(block.timestamp * 1 days > auctions[msg.sender].endTimestamp, "Auction is in progress");
        require(secret == auctions[msg.sender].ownerWithdrawSecret, "Wrong secret given");

        // todo transfer

        return auctions[msg.sender].currentBid;
    }



    function totalAuctionsDeployed () external returns ( uint256 ) {
        return countTotalAuctionsDeployed;
    }

    // string private greeting;
    // address private lastAddressChanger;

    // constructor(string memory _greeting) {
    //     console.log("Deploying a Greeter with greeting:", _greeting);
    //     greeting = _greeting;
    //     lastAddressChanger = msg.sender;
    // }

    // function greet() public view returns (string memory) {
    //     return greeting;
    // }

    // function setGreeting(string memory _greeting) public {
    //     console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
    //     lastAddressChanger = msg.sender;
    //     greeting = _greeting;
    // }

    // function getLastAddressChanger() public view returns (address) {
    //     return lastAddressChanger;
    // }
    


}


/**
contract example {

    // Define variable owner of the type address
    address owner;

    // this function is executed at initialization and sets the owner of the contract
    function example() {
        owner = msg.sender; 
    }

    function doSomething() {
        if (msg.sender == owner) {
            // only the owner can do something, like storage access
        }
    }
}

 */


 /* EX : event

 // SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract TestContract {
    struct MyStruct {
        string a;
        string b;
    }
    
    event FCalled(MyStruct[] _a);

    function f() public {
        MyStruct[] memory a = new MyStruct[](2);
        
        MyStruct memory s1 = MyStruct("s1a", "s1b");
        MyStruct memory s2 = MyStruct("s2a", "s2b");
    
        a[0] = s1;
        a[1] = s2;
        
        emit FCalled(a);
    }
}*/