// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SampleERC721
 * @dev Create a sample ERC721 standard token
 */
contract DappLock is Ownable,ERC1155("https://ibb.co/cFsJP1L") {

    mapping(address => mapping(uint256 => uint256)) public rentRecords;

    function rentToken(uint256 tokenIdForRent)
    public 
    payable
    {
    require(tokenIdForRent != 0,"Token doesn't exist. Choose from (1,2)");
    require(tokenIdForRent < 3,"Token doesn't exist. Choose from (1,2)");
    require(balanceOf(msg.sender,tokenIdForRent) < 1,"Wallet already owns token.");
    require(msg.value >= 0.001 ether,"Not enough ether sent. Price is 0.001 ether.");
    _mint(msg.sender,tokenIdForRent,1,"");
    rentRecords[msg.sender][tokenIdForRent] = block.timestamp;
    }

    function withdraw()
    public
    onlyOwner
    {
    require(address(this).balance > 0,"Balance is 0.");
    payable(owner()).transfer(address(this).balance);
    }

    function checkDoorAccess(address doorUser,uint256 tokenIdToCheck)
    public
    returns(bool)
    {
    require(tokenIdToCheck != 0,"Token doesn't exist. Choose from (1,2)");
    require(tokenIdToCheck < 3,"Token doesn't exist. Choose from (1,2)");
    if(balanceOf(doorUser,tokenIdToCheck) < 1){
        return false;
    }else{
        if((block.timestamp - rentRecords[doorUser][tokenIdToCheck]) >= 30 minutes){
            _burn(doorUser,tokenIdToCheck,1);
            return false;
        }else{
            return true;
        }
    }
    }

}