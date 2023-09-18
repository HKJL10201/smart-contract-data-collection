// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GodToken is ERC721, Ownable {
  constructor(string memory _name, string memory _symbol)
    ERC721(_name, _symbol)
  {}

  uint256 counter;

  uint256 fee = 0.001 ether;

  struct God {
    string name;
    uint256 id;
    uint256 dna;
    uint8 level;
    uint8 rarity;
    uint8 attack;
    uint defense;
    uint stamina;
  }

  God[] public Gods;

  event NewGod(address indexed owner, uint256 id, uint256 dna);
event OldGod(address indexed owner, uint256 id, uint256 dna);
  function _createRandomNum(uint256 _mod) internal view returns (uint256) {
    uint256 randomNum = uint256(
      keccak256(abi.encodePacked(block.timestamp, msg.sender))
    );
    return randomNum % _mod;
  }

  function _createGod(string memory _name) internal {
    uint8 randRarity = uint8(_createRandomNum(100));
    uint256 randDna = _createRandomNum(10**16);
    uint8 randattack = uint8(_createRandomNum(100));
    uint8 randdefense = uint8(_createRandomNum(100));
    uint8 randstamina = uint8(_createRandomNum(100));

    God memory newGod = God(_name, counter, randDna, 1, randRarity,randattack,randdefense,randstamina);
    Gods.push(newGod);
    _safeMint(msg.sender, counter);
    emit NewGod(msg.sender, counter, randDna);
    counter++;
  }

  function createRandomGod(string memory _name) public payable {
    require(msg.value >= fee);
    _createGod(_name);
  }

 
  function getGods() public view returns (God[] memory) {
    return Gods;
  }

  function getOwnerGods(address _owner) public view returns (God[] memory) {
    God[] memory result = new God[](balanceOf(_owner));
    uint256 cnt = 0;
    for (uint256 i = 0; i < Gods.length; i++) {
      if (ownerOf(i) == _owner) {
        result[cnt] = Gods[i];
        cnt++;
      }
    }
    return result;
  }

  function levelUp(uint256 _GodId) public {
    require(ownerOf(_GodId) == msg.sender);
    God storage gd = Gods[_GodId];
    gd.level++;
  }
}
