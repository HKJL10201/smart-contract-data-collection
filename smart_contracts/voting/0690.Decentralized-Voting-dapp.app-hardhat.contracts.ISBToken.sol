// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface ISBToken {
    function createSoul(
        address addrSoul,
        string calldata _name,
        uint _age
    ) external;

    function turnKYC(address addrSoul, bool _kyc) external;

    function getRole(address addrSoul) external view returns (uint8);

    function checkKYC(address addrSoul) external view returns (bool);

    function checkIdentity(address addrSoul) external view returns (bool);

    function getOwner(address addrSoul) external view returns (address);
}
