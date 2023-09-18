// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Poap is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // solhint-disable no-empty-blocks
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // Empty constructor
    }

    function grantPoap(address attendee) public returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(attendee, newItemId);

        return newItemId;
    }
}
