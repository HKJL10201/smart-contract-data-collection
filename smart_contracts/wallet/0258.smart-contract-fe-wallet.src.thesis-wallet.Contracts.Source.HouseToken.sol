pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract HouseToken is ERC721 {
	uint256 tokenId;
	
    constructor() ERC721("House Token", "HT") public payable {
		tokenId = 0;
	}

	function GetPropertyToken(uint256 propertyId) public {
		_safeMint(msg.sender, propertyId);
	}

	function GiveTokenAccess(uint256 propertyId, address contractAddress) public {
		approve(contractAddress, propertyId);
	}
}