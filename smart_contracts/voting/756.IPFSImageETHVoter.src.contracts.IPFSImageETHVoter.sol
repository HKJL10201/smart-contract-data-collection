// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.16;

contract IPFSImageVoter {
  string public name = "IPFSImageVoter";

  //store images
  uint public imageCount = 0;
  uint public tip = 0;
  mapping(uint => Image) public images;

  struct Image {
    uint id;
    string hash;
    string description;
    uint tipAmount;
    address payable author;
  }

  event ImageCreated(
    uint id,
    string hash,
    string description,
    uint tipAmount,
    address payable author
  );

  event ImageTipped (
    uint id,
    string hash,
    string description,
    uint tipAmount,
    address payable author
  );

  //create images
  function uploadImage(string memory imgHash, string memory description) public {
    require(bytes(description).length > 0);
    require(bytes(imgHash).length > 0);
    require(msg.sender != address(0x0));
    
    imageCount++;
    images[imageCount] = Image(imageCount, imgHash, description, 0, msg.sender);

    emit ImageCreated(imageCount, imgHash, description, 0, msg.sender);
  }
  
  //tip images
  function tipImageOwner(uint id) public payable {
    require(id > 0 && id <= imageCount);
    //Fetch image by id
    Image memory image = images[id];
    address payable author = image.author;
    address(author).transfer(msg.value);
    image.tipAmount = image.tipAmount + msg.value;
    images[id] = image;
    emit ImageTipped(id, image.hash, image.description, image.tipAmount, author);
  }
}