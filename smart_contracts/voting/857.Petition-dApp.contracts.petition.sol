// SPDX-License-Identifier: MIT

pragma solidity^0.7.0;

/// @title petition

/**
 * @title petition
 * @dev allows KYC verified users to sign a petition using the Ethereum blockchain
 */

contract petition {

    address owner;
    address[] signers;

    mapping(address => bool) kycComplete;
    mapping(address => bool) hasSigned;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Must be contract owner");
        _;
    }

    function addKyc (address _address) public onlyOwner {
        kycComplete[_address] = true;
    }

    function checkKyc () public view returns(bool) {
        return kycComplete[msg.sender];
    }

    function sign () public {
        require(kycComplete[msg.sender]==true, "You must complete KYC before signing.");
        require(hasSigned[msg.sender]==false, "You have already signed this petition.");
        hasSigned[msg.sender] = true;
        signers.push(msg.sender);
    }

    function checkIfSigned () public view returns(bool) {
        return hasSigned[msg.sender];
    }

    function getNumberOfSignitures () public view returns(uint) {
        return signers.length;
    }

}
