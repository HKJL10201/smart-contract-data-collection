//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract Nft is ERC721, Ownable, Pausable {
    uint256 public tokenCounter;
    mapping(address => bool) blackList;

    constructor() public ERC721("Alien World", "AW") {
        _setBaseURI("https://ipfs.io/ipfs/");
        tokenCounter = 1;
    }

    function mintItemToAdress(address to, string memory tokenURI)
        public
        whenNotPaused
        returns (uint256)
    {
        require(blackList[to] == false, "Account blacklisted");

        uint256 id = tokenCounter;
        _mint(to, id);
        _setTokenURI(id, tokenURI);

        tokenCounter = tokenCounter + 1;

        return id;
    }

    function mintItem(string memory tokenURI)
        public
        whenNotPaused
        returns (uint256)
    {
        require(blackList[msg.sender] == false, "Account blacklisted");

        uint256 id = tokenCounter;
        _mint(msg.sender, id);
        _setTokenURI(id, tokenURI);

        tokenCounter = tokenCounter + 1;

        return id;
    }

    function blacklist(address _black) public onlyOwner {
        blackList[_black] = true;
    }

    function removeFromblacklist(address _white) public onlyOwner {
        blackList[_white] = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
