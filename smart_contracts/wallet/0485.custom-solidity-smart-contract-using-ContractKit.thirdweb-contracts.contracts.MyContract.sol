// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";
import "@thirdweb-dev/contracts/extension/Permissions.sol";

contract Contract is ERC721Drop, Permissions {
    mapping (uint256 => string) public notes;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function writeNote(uint256 _tokenId, string memory _msg) public {
        require(msg.sender == ownerOf(_tokenId), "Not owner");
        notes[_tokenId] = _msg;
    }
    // https://thirdweb.com/goerli/0x3d746d0744D38999480836b0498b995B5D59E18c/explorer
    // Write Note (writeNote) NONPAYABLE
    // Token Id _tokenId uint256
    // Msg _msg string


    function overrideNote(
        uint256 _tokenId,
        string memory _msg
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        notes[_tokenId] = _msg;
    }
}