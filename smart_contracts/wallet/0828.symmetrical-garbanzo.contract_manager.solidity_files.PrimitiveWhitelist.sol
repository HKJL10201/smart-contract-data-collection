// SPXD-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @notice This is a contract that can be used to white list addresses. The way adresses are whitelisted
            in this contract is called primitive as it is relatively unefficient in regard to gas usage.
*/
contract PrimitiveWhitelist {
    uint8 public maxWhitelistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    uint8 public numAdressesWhitelisted;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addWhitelistAddress() public {
        require(!whitelistedAddresses[msg.sender], "Sender is already whitelisted.");
        require(numAdressesWhitelisted < maxWhitelistedAddresses, "Max number of addresses reached.");

        whitelistedAddresses[msg.sender] = true;
        numAdressesWhitelisted += 1;
    }
}