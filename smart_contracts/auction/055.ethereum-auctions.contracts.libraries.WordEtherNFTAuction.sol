pragma solidity ^0.4.18;

import "../WordBid.sol";
import "../EtherBidAuction.sol";
import "../NFTAuction.sol";
import "../ProxyAuction.sol";

contract WordEtherNFTAuction is WordBid, EtherBidAuction, NFTAuction {
}

contract WordEtherNFTAuctionAssemblyLine is WordEtherNFTAuction {
    WordEtherNFTAuction lib = new WordEtherNFTAuction();
    string identifier = "WordEtherNFTAuction_1";

    function WordEtherNFTAuctionAssemblyLine() public {
        lib.fix();
    }

    /// Prepare an auction for asset with ID `_assetId` on the registry at `_assetRegistry` in exchange for Ether in minimum increments of `_fixedIncrement` or current bid / `_fractionalIncrement`, whichever is greater, ending at epoch `_endTime` or `_extendBlocks` blocks after the last bid (both inclusive, whichever comes last, choose a sufficient number of blocks to decrease the chance of miner frontrunning) . Call start() after transferring the asset to the auction's address.
    function create(
        bool _proxy,
        address _assetRegistry,
        uint256 _assetId,
        address _bidToken,
        uint40 _endTime,
        uint32 _extendBlocks,
        uint80 _fixedIncrement,
        uint24 _fractionalIncrement,
        uint _reservePrice,
        address _beneficiary
    ) public returns (address)
    {
        WordEtherNFTAuction auction = WordEtherNFTAuction(0x0);
        if (_proxy) {
            auction = WordEtherNFTAuction(new ProxyAuction(lib));
        } else {
            auction = new WordEtherNFTAuction();
        }
        auction.initNFT(_assetRegistry, _assetId);
        auction.init(_endTime, _extendBlocks, _fixedIncrement, _fractionalIncrement, _reservePrice, _beneficiary);
        factory.registerAuction(identifier, auction);
        return auction;
    }
}