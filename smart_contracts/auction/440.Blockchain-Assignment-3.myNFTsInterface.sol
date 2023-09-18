//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface DigitalArt {
    function digiArt(uint256) external view returns(
        uint256,
        string memory,
        string memory,
        address
    );

    function artCount() external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function transfer(uint256, address) external;

    function getArtist(uint256) external view returns(address);
}
