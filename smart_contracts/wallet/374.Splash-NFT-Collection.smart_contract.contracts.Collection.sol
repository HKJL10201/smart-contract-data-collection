//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import { Base64 } from "./libraries/Base64.sol";

// Extends ERC721URIStorage.
contract Collection is ERC721URIStorage {
    
    using Counters for Counters.Counter;
    // The unique identifiers.
    Counters.Counter private _tokenIds;

    // BaseSVG
    string baseSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: Lato; font-size: 24px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    string coloredSvg1 = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: Lato; font-size: 24px; }</style><rect width='100%' height='100%' fill=";

    string coloredSvg2 = " /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    constructor() ERC721 ("MyNFT", "CHIRAG") {
    console.log("This is my NFT contract. Woah!");
  }

  string[] first_words = ["Grotesque", "Colossal", "Ginormous", "Epic", "Hot", "Powerful"];
  string[] second_words = ["Avocado", "Sandwich", "Omlette", "Peach", "Cupcake", "Cookie"];
  string[] third_words = ["Pikachu", "Charmander", "Squirtle", "Bulbasaur", "Pidgey", "Pidgeotto"];
  string[] colors = ["'#23d997'", "'#b847ff'", "'#ff2efc'", "'#ff5473'", "'#00d664'", "'#ffba24'", "'#40ffc2'", "'#3ef4fa'"];

  event NFTMintedEvent(address sender, uint256 tokenId);

    // We can't generate truly random numbers, as everything on the blockchain is public and anyone can replicate your source of randomness.
    // view keyword - Read-only.
    function randomFirstWord(uint256 newId) public view returns (string memory){
        // Generate a random number between 0 and 5.
        uint256 randomNumber = uint(keccak256(abi.encodePacked("FIRST_WORD", Strings.toString(newId)))) % first_words.length;
        return first_words[randomNumber];
    }
    
    function randomSecondWord(uint256 newId) public view returns (string memory){
        // Generate a random number between 0 and 5.
        uint256 randomNumber = uint(keccak256(abi.encodePacked("SECOND_WORD", Strings.toString(newId)))) % second_words.length;
        return second_words[randomNumber];
    }
    function randomThirdWord(uint256 newId) public view returns (string memory){
        // Generate a random number between 0 and 5.
        uint256 randomNumber = uint(keccak256(abi.encodePacked("THIRD_WORD", Strings.toString(newId)))) % third_words.length;
        return third_words[randomNumber];
    }
    
    function randomColor(uint256 newId) public view returns (string memory){
        // Generate a random number between 0 and 5.
        uint256 randomNumber = uint(keccak256(abi.encodePacked("COLOR", Strings.toString(newId)))) % colors.length;
        return colors[randomNumber];
    }
    

  function makeNFT() public {
    //   Create a new token Id using the counter.
    uint256 newId = _tokenIds.current();

    string memory firstWord = randomFirstWord(newId);
    string memory secondWord = randomSecondWord(newId);
    string memory thirdWord = randomThirdWord(newId);
    string memory combinedWord = string(abi.encodePacked(firstWord, secondWord, thirdWord));

    string memory color = randomColor(newId);

    string memory finalSvg = string(abi.encodePacked(coloredSvg1, color, coloredSvg2, combinedWord, "</text></svg>"));

    // // Concatenate baseSVG with words
    // console.log(finalSvg);

    string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"name": "',
                    // We set the title of our NFT as the generated word.
                    combinedWord,
                    '", "description": "Random Name Generator", "image": "data:image/svg+xml;base64,',
                    // We add data:image/svg+xml;base64 and then append our base64 encode our svg.
                    Base64.encode(bytes(finalSvg)),
                    '"}'
                )
            )
        )
    );
    
    string memory finalTokenUri = string(
        abi.encodePacked("data:application/json;base64,", json)
    );

    console.log(finalTokenUri);

    // Mint the NFT to the sender using the new ID. The sender is the owner of the thing they want to make an NFT.
    _safeMint(msg.sender, newId);

    // Add data to the NFT, here its just a link. It can be a picture, a video, a link to a website, etc.
    _setTokenURI(newId, finalTokenUri);

    console.log("An NFT of ID %s has been minted to %s", newId, msg.sender);

    // Increment the counter for next NFT generation. Or you could call increment at the start and not current. That will prevent you from executing the folllowing line.
    _tokenIds.increment();

    // Emit the event.
    emit NFTMintedEvent(msg.sender, newId);
  }
    
}

// At a basic level, events are messages our smart contracts throw out that we can capture on our client in real-time. Just because the transaction is minted, it doesn't mean it will result in a success. It may error out, but the transaction is still mined in the process. We pass the newId from the smartContract to the front-end, and the front-end can capture that and use it somewhere.

// Remember that the bytecodes of the contract which you have deployed represent a series of opcodes in the EVM (Ethereum Virtual Machine) that will perform instructions for us onchain.