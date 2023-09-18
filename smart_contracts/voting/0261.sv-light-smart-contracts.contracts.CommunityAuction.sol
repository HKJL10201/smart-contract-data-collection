pragma solidity 0.4.24;


/**
    Manage community ballot prices.
 */


import {owned} from "./SVCommon.sol";


interface CommAuctionIface {
    function getNextPrice(bytes32 democHash) external view returns (uint);
    function noteBallotDeployed(bytes32 democHash) external;

    // add more when we need it

    function upgradeMe(address newSC) external;
}


contract CommunityAuctionSimple is owned, CommAuctionIface {
    // about $1USD at $600usd/eth
    uint public commBallotPriceWei = 1666666666000000;

    struct Record {
        bytes32 democHash;
        uint ts;
    }

    mapping (address => Record[]) public ballotLog;
    mapping (address => address) public upgrades;

    function getNextPrice(bytes32) external view returns (uint) {
        return commBallotPriceWei;
    }

    function noteBallotDeployed(bytes32 d) external {
        require(upgrades[msg.sender] == address(0));
        ballotLog[msg.sender].push(Record(d, now));
    }

    function upgradeMe(address newSC) external {
        require(upgrades[msg.sender] == address(0));
        upgrades[msg.sender] = newSC;
    }

    function getBallotLogN(address a) external view returns (uint) {
        return ballotLog[a].length;
    }

    function setPriceWei(uint newPrice) only_owner() external {
        commBallotPriceWei = newPrice;
    }
}
