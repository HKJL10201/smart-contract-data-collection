// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract nft_explorer is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nftID;

    struct data {
        address Address;
        uint256 XP;
    }

    mapping(uint256 => data) public owners;
    address public _XpTokenAddress; ///////XpToken ADDRESS SAVES HERE(!!1) --- !!0

    constructor() ERC721("", "") {}

    function mapNFT(address add, uint256 xp) external {
        owners[_nftID.current()].Address = add;
        owners[_nftID.current()].XP = xp;
        _nftID.increment();
    }

    function xpToNFT(
        address from,
        uint256 nftID,
        uint256 xp
    ) external returns (bool) {
        require(from == owners[nftID].Address, "Your are not NFT owner");
        require(
            msg.sender == _XpTokenAddress,
            "msg sender should be the XpToken"
        );
        owners[nftID].XP += xp;
        return true;
    }

    function nftOwner(uint256 nftID) public view returns (address) {
        return owners[nftID].Address;
    }

    function XpAmount(uint256 nftID) public view returns (uint256) {
        return owners[nftID].XP;
    }

    ////////////////////////////////////////////THIS FUNCTION IS JUST FOR TEST PURPOSES(!!0) --- !!1
    function setAddress(address add) public onlyOwner {
        _XpTokenAddress = add;
    }
}
