// SPXD-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrimitiveWhitelist {
    function whitelistedAddresses(address) external view returns (bool);
}