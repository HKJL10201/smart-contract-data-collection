pragma solidity ^0.5.0;

contract CulturestakeI {
    function burnNonce(address, uint256) public;
    function isOwner(address) public view returns (bool);
    function isVoteRelayer(address) public view returns (bool);
    function questionsByAddress(address) public returns (bool);
    function isActiveFestival(bytes32) public returns (bool);
    function getQuestion(bytes32) public view returns (bool, bool, address, bytes32, uint256);
}