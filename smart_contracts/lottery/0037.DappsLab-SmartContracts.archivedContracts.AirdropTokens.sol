// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MerkleProof} from "../openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AirdropTokens is Ownable{

    event GainsClaimed(address indexed _address, uint256 _value);

    ERC20 private _token; // getters and setters
    using MerkleProof for bytes32[];
    uint256 public totalTokens;
    address[] public users;

    mapping(address => uint256) public claimed;
    bytes32 merkleRoot;
    bool public isAirdropped;
    constructor() Ownable(){

    }

    function setMerkleRootAndAirDrop(bytes32 root) onlyOwner public
    {
        merkleRoot = root;
        totalTokens = _token.balanceOf(address(this));
        isAirdropped = true;
    }

    function getTotalTokens() public view returns(uint256){
        return totalTokens;
    }

    function getUsers() public view returns(address[] memory) {
        return users;
    }


    function getToken() public view returns (ERC20){
        return _token;
    }

    //  ERC20 private _token; // getters and setters
    function setToken(address tokenAddress) onlyOwner public {
        _token = ERC20(tokenAddress);
    }

    function getProof(bytes32[] memory proof) public view returns(bool){
        if(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender)))){
            return true;
        }else{
            return false;
        }
    }

    function addUsers(address[] memory userAddresses) onlyOwner public {
        if (users.length == 0) {
            users = userAddresses;
        } else {
            for (uint i=0; i < userAddresses.length; i++) {
                users.push(userAddresses[i]);
            }
        }
    }

    function claim(bytes32[] memory proof, uint claimAmount) public {
        const root = merkleRootMap[claimAmount];
        require(root != 0, "AirdropTokens not available yet!");

        require(proof.verify(root, keccak256(abi.encodePacked(msg.sender))), "You are not in the list");

        uint256 total = totalTokens/users.length;

        require(_token.transfer(msg.sender, total), "Transfer failed.");
        emit GainsClaimed(msg.sender, total);
    }

//     User can't claim twice
//    Owner can withdraw tokens from Conteact at anytime.

}
