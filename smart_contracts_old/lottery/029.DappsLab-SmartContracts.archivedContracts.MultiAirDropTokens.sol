// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MerkleProof} from "../openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MultiAirdropTokens is Ownable{

    event GainsClaimed(address indexed _address, uint256 _value);

    ERC20 private _token; // getters and setters
    using MerkleProof for bytes32[];
    uint256 public totalTokens;

    mapping(uint256 => mapping(address => bool)) public isClaimed;
    mapping (uint256 => bytes32) merkleRootMap;
    bool public isAirdropped;
    constructor(address tokenAddress) Ownable(){
        _token = ERC20(tokenAddress);
    }

    function setMerkleRootAndAirDrop(uint256 sendAmount, bytes32 root) onlyOwner public
    {
        merkleRootMap[sendAmount] = root;
        totalTokens = _token.balanceOf(address(this));
    }

    function setAirDrop(bool value) onlyOwner public{
        isAirdropped = value;
    }

    function getTotalTokens() public view returns(uint256){
        return totalTokens;
    }



    function getToken() public view returns (ERC20){
        return _token;
    }

    //  ERC20 private _token; // getters and setters
    function setToken(address tokenAddress) onlyOwner public {
        _token = ERC20(tokenAddress);
    }

    function getProof(uint256 sendAmount, bytes32[] memory proof) public view returns(bool){
        if(proof.verify(merkleRootMap[sendAmount], keccak256(abi.encodePacked(msg.sender)))){
            return true;
        }else{
            return false;
        }
    }


    function claim(bytes32[] memory proof, uint claimAmount) public {
        require(isAirdropped == true, "AirdropTokens not available yet!");
        require(merkleRootMap[claimAmount] != 0x0000000000000000000000000000000000000000000000000000000000000000, "Invalid Claim Amount");
        require(!isClaimed[claimAmount][msg.sender], "Already Claimed this Claim Amount");
        require(proof.verify(merkleRootMap[claimAmount], keccak256(abi.encodePacked(msg.sender))), "You are not in the list");
        require(_token.transfer(msg.sender, claimAmount), "Transfer failed.");
        isClaimed[claimAmount][msg.sender] = true;
        emit GainsClaimed(msg.sender, claimAmount);
    }

    function withdraw(uint256 amount) onlyOwner public{
        require(_token.transfer(msg.sender, amount), "Transfer failed.");
    }

    function withdrawAll() onlyOwner public{
        uint256 total = _token.balanceOf(address(this));
        require(_token.transfer(msg.sender, total), "Transfer failed.");
    }

    //     User can't claim twice
    //    Owner can withdraw tokens from Conteact at anytime.

}
