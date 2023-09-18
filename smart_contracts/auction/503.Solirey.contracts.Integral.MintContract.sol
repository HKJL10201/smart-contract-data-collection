// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Solirey.sol";

contract MintContract is Solirey {
    using Counters for Counters.Counter;
    
    function mintNft(address receiver) external returns (uint256) {
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _safeMint(receiver, newNftTokenId);

        return newNftTokenId;
    }
}
