// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "lib/solmate/src/tokens/ERC721.sol";

contract GovToken is ERC721 {
    uint256 public totalSupply;

    constructor() ERC721("BordaToken", "BTK") {}

    function tokenURI(uint256 id) public pure override returns (string memory) {
        return
            "ipfs://QmUH3NdvuUmySGa4Jj6b4Xj9UcP45xTvTqr8idTrwVAeuR/test.json";
    }

    function mint(address _to) external {
        _safeMint(_to, totalSupply);
        totalSupply = totalSupply + 1;
    }

    function snapshot() external view returns (address[] memory) {
        address[] memory addrArray;
        for (uint256 i = 0; i < totalSupply; i++) {
            addrArray[i] = ownerOf[i];
        }
        return addrArray;
    }
}
