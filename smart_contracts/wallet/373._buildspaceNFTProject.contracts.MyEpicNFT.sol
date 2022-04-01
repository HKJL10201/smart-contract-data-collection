// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
// importing OpenZeppelin contracts for an ERC compliant NFT token and a counter
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

// import the helper function that encodes base64
import { Base64 } from "./libraries/Base64.sol";

// We inherit the contract we imported. This means we'll have access
// to the inherited contract's methods.
contract MyEpicNFT is ERC721URIStorage {
  // openzeppelin counter
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIDs;

  // We split the SVG at the part where it asks for the background color.
  string svgPartOne = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='";
  string svgPartTwo = "'/><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

  // I create three arrays, each with their own theme of random words.
  // Pick some random funny words, names of anime characters, foods you like, whatever! 
  string[] firstWords = ["amine", "kanye", "war", "shrink", "cole", "eminmen"];
  string[] secondWords = ["soccer", "tennis", "baseball", "tank", "french", "football"];
  string[] thirdWords = ["august", "regal", "fanta", "progress", "empath", "socks"];

  // Get fancy with it! Declare a bunch of colors.
  string[] colors = ["red", "#08C2A8", "black", "pink", "blue", "green", "orange"];

  // capture the new mint in an event
  event NewEpicNFTMinted(address sender, uint256 tokenId);

  // constructor now passes name of my NFT and the coin symbol
  // designation that deployment follow ERC721 standard
  constructor() ERC721 ("LoPfeifNFT", "LOPFEIF") {
    console.log("NFT Contract deployed");
  }

  // randomly pick a word from each array using a stringified version of tokenID +
  // the phrase "FIRST_WORD" and running it through an encoder for a source of randomness
  // !! not truly random and easy to take advantage of but this is for educational purposes only
  function pickRandomFirstWord(uint256 tokenId) public view returns (string memory) {
    // Seed the random generator with known items 
    uint256 rand = random(string(abi.encodePacked("FIRST_WORD", Strings.toString(tokenId))));
    // Squash the # between 0 and the length of the array to avoid going out of bounds.
    rand = rand % firstWords.length;
    return firstWords[rand];
  }

  function pickRandomSecondWord(uint256 tokenId) public view returns (string memory) {
    uint256 rand = random(string(abi.encodePacked("SECOND_WORD", Strings.toString(tokenId))));
    rand = rand % secondWords.length;
    return secondWords[rand];
  }

  function pickRandomThirdWord(uint256 tokenId) public view returns (string memory) {
    uint256 rand = random(string(abi.encodePacked("THIRD_WORD", Strings.toString(tokenId))));
    rand = rand % thirdWords.length;
    return thirdWords[rand];
  }

  // Same old stuff, pick a random color.
  function pickRandomColor(uint256 tokenId) public view returns (string memory) {
    uint256 rand = random(string(abi.encodePacked("COLOR", Strings.toString(tokenId))));
    rand = rand % colors.length;
    return colors[rand];
  }

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getTotalNFTsMinted() public view returns (uint256) {
    uint256 numNFTs = _tokenIDs.current();
    return numNFTs;
  }

  // user mints an NFT
  function makeAnEpicNFT() public {
    // get current token ID, starting at 0
    uint256 newItemID = _tokenIDs.current();

    require(newItemID < 50);

    // We go and randomly grab one word from each of the three arrays.
    string memory first = pickRandomFirstWord(newItemID);
    string memory second = pickRandomSecondWord(newItemID);
    string memory third = pickRandomThirdWord(newItemID);
    string memory combinedWord = string(abi.encodePacked(first, second, third));

     // Add the random color in.
    string memory randomColor = pickRandomColor(newItemID);
    string memory finalSvg = string(abi.encodePacked(svgPartOne, randomColor, svgPartTwo, combinedWord, "</text></svg>"));

    // Get all the JSON metadata in place and base64 encode it.
    string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"name": "',
                    combinedWord,
                    '", "description": "A highly acclaimed collection of LoFi squares.", "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(finalSvg)),
                    '"}'
                )
            )
        )
    );

    // Just like before, we prepend data:application/json;base64, to our data.
    string memory finalTokenUri = string(
        abi.encodePacked("data:application/json;base64,", json)
    );

    console.log("\n--------------------");
    console.log(finalTokenUri);
    console.log("--------------------\n");

    _safeMint(msg.sender, newItemID);
    
    // Update your URI!!!
    _setTokenURI(newItemID, finalTokenUri);
  
    _tokenIDs.increment();
    console.log("An NFT w/ ID %s has been minted to %s", newItemID, msg.sender);

    // post txn data to the blockchain via "emit"
    emit NewEpicNFTMinted(msg.sender, newItemID);
  }
}