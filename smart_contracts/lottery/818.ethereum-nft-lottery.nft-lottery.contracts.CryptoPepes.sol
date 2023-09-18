// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


/// @author Matteo Pinna
/// @title An NFT ERC721 contract for Pepe The Frog NFTs
contract CryptoPepes is ERC721 {

    // Counter for managing token IDs
    uint internal _tokenCount;

    // Owner of the loterry (and default owner of minted NTFs)
    address private _owner;

    // Mapping from tokenId to NFT
    mapping(uint => Pepe) private _pepes;

    // Mapping from rank to list of NFTs
    mapping(uint => uint[]) private _availablePepes;

    // Struct representing an NFT metadata
    struct Pepe {
        string description;
        uint rank;
    }
    

    /**
    * @dev Initializes the contract by setting a <name> and a <symbol> to the token collection, 
    * and mints first <4> NFTs.
    */
    constructor() ERC721("CryptoPepes", "CP") {
        _owner = msg.sender;

        // Mint first NFTs
        for(uint i = 0; i < 4;) {
            _safeMint(_owner, i);
            _pepes[i] = Pepe(_randomDescription(i), (i % 8) + 1);
            _availablePepes[(i % 8) + 1].push(i);

            unchecked { i++; }
        }
        _tokenCount = 4;
    }

    /**
     * @dev Get the list of tokenIds of NFT with rank <rank>
     *
     * @return uint[] list
     */
    function getAvailablePepes(uint rank) public view returns(uint[] memory) {
        return _availablePepes[rank];
    }

    /**
     * @dev Get the description of <tokenId> NFT.
     *
     * @return string description
     */
    function descriptionOf(uint tokenId) public view returns(string memory) {
        string memory description = _pepes[tokenId].description;
        require(bytes(description).length != 0, "description query for nonexistent token");
        return description;
    }

    /**
     * @dev Get the rank of <tokenId> NFT.
     *
     * @return uint rank
     */
    function rankOf(uint tokenId) public view returns(uint) {
        uint rank = _pepes[tokenId].rank;
        require(rank != 0, "rank query for nonexistent token");
        return rank;
    }

    function isAvailable(uint rank) public view returns(bool) {
        require(rank > 0 && rank <= 8, "query for nonexistent rank");
        if(_availablePepes[rank].length == 0) {
            return false;
        }
        return true;
    }

    /**
     * @dev Randomly picks an NFT (tokenId) with a specific <rank>, if available, and transfers it to <to>.
     * 
     */
    function transferNFT(address to, uint rank) internal returns(bool) {
        require(rank > 0 && rank <= 8, "non existent rank (1-8 only)");

        uint randIndex = _random(rank) % _availablePepes[rank].length;
        uint tokenId = _availablePepes[rank][randIndex];
        uint[] memory aux = _availablePepes[rank];

        // write the last tokenId of the array to the random index position.
        // thus we take out the used assigned tokenId from the circulation and store the last tokenId of the array for future use 
        aux[randIndex] = aux[aux.length - 1];

        // reduce the size of the array by 1 (this deletes the last record we’ve copied at the previous step)
        // to get rid of assigned NFTs
        assembly { mstore(aux, sub(mload(aux), 1)) }

        _availablePepes[rank] = aux;

        safeTransferFrom(_owner, to, tokenId);

        return true;
    }

    /**
     * @dev Mint an NFT with a specific <rank> and transfer it to <to>.
     */
    function mintNFT(address to, uint rank) internal returns(bool) {
        require(rank > 0 && rank <= 8, "non existent rank (1-8 only)");

        _safeMint(to, _tokenCount);
        _pepes[_tokenCount] = Pepe(_randomDescription(_tokenCount), rank);
        _tokenCount++;

        return true;
    }

    /**
     * @dev Generate a pseudo-random number.
     *
     * @return uint pseudo-random
     */
    function _random(uint seed) internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, seed)));
    }

    /**
     * @dev Generate a pseudo-random string.
     * 
     * @return string pseudo-random
     */
    function _randomDescription(uint seed) private view returns(string memory) {
        // For generating random Pepe descriptions
        string[7] memory _names = ["LordPepe", "MarieLePepe", "Pepe", "PepePolice", "PepeSoldier", "PepeWizard", "TrumPepe"];
        string[10] memory _characteristics = ["Anxious", "Enlightened", "Ghotic", "Happy", "Old", "Rich", "Sad", "Strong", "Suggestive", "Young"];

        uint randomIndexPepes = _random(seed) % _names.length;
        uint randomIndexcharacteristics = _random(randomIndexPepes) % _characteristics.length;

        return string.concat(_characteristics[randomIndexcharacteristics], " ", _names[randomIndexPepes]);
    }
}