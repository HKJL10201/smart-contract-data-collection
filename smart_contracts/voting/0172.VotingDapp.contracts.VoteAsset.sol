// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//Vote NFT contract of village chief election.
contract VoteAsset is ERC721PresetMinterPauserAutoId 
{
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdTracker;
    // minting event
    event mintingEvent(address mintedAddress);

    mapping(address => bool) public mintersMap;

    constructor() ERC721PresetMinterPauserAutoId("VoteAsset", "VAST", "https://gateway.pinata.cloud/ipfs/QmVfcSFoUJ5CEMgPXAdZnabhsHVq9XuJUDpmwruyMCgEV2/") {}

    // Overriding mint function to remove minter role so that everyone can mint nft.
    function mint(address to) public override virtual 
    {
        // Voters cannot mint NFT more than once.
        assert(mintersMap[msg.sender] == false);

        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();

        // Voter has minted.
        mintersMap[msg.sender] = true;
        emit mintingEvent(to);
    }

    function getContractAddress() public view returns (address)
    {
        return address(this);
    }
}