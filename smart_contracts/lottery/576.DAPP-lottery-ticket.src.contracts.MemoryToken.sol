pragma solidity ^0.5.0;

import "./ERC721Full.sol";

contract MemoryToken is ERC721Full {

    constructor() ERC721Full("Memory Token", "MEMORY") public {
    }

    function mint(address _to, string memory _tokenURI) public returns (bool) {
        //increment total supply by 1 and make it the tokenId of the newly minted token
        uint _tokenId = totalSupply().add(1);

        //use ERC721Full _mint function to mint token
        _mint(_to, _tokenId);

        //link tokenURI (data) to tokenId
        _setTokenURI(_tokenId, _tokenURI);
        return true;
    }
}
