// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract IPFSFileStorage {

    struct UploadedFile {
        address owner;
        string url;
    }

    event NewUpload(address indexed owner, string url);

    UploadedFile[] private UploadedFiles;

    function setUploadedFiles(string memory _url) public {
        UploadedFiles.push(UploadedFile(msg.sender, _url));
        emit NewUpload(msg.sender, _url);
        
    }

    function getUploadedFiles() public view returns (UploadedFile[] memory) {
        return UploadedFiles;
    }
    
}