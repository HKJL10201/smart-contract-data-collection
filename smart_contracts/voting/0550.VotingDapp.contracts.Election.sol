// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Election is ERC721, ERC721Enumerable {
    constructor() ERC721("Election", "CCS") {
        //hi
    }

    struct candidate {
        uint256 id;
        string name;
        uint256 votecount;
    }

    mapping(address => bool) public voters;
    mapping(uint256 => candidate) public candidates;
    // Store Candidate Count;
    uint256 public candidatesCount;
    string[] public candi;
    mapping(string => bool) _candiExists;

    function Contestent(string memory _name) public {
        addCandidate(_name);
    }

    function addCandidate(string memory _name) private {
        require(!_candiExists[_name]);
        candi.push(_name);
        candidatesCount++;
        _mint(msg.sender, candidatesCount);
        _candiExists[_name] = true;
        candidates[candidatesCount] = candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        require(!voters[msg.sender]);
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        voters[msg.sender] = true;
        candidates[_candidateId].votecount++;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
