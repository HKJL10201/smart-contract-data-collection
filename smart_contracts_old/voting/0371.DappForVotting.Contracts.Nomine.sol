//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./Roles.sol";
import "./ownable.sol";

contract Nomine is Ownable {
    
    address private _owner;
    using Roles for Roles.Role;
    Roles.Role private nomine;
    
    
    mapping (address => uint128) internal nomineNumber;
    mapping (uint128 => address) internal nomineAddress;
    // mapping (address => uint) internal nomineVotes;
    
    event nomineAdded(address indexed account);
    event nomineRemoved(address indexed account);
    
    constructor() {
        _owner = msg.sender;
    }
    
    modifier isAlreadyNominee(address _address) {
        require(isNominee(_address));
        _;
    }
    
    modifier isNotNominee(address _address) {
        require(!isNominee(_address));
        _;
    }
    
    function isNominee(address _address) view private returns(bool) {
        return nomine.has(_address);
    }
    
    function addNomine(address _address, string memory _addharCard, string memory _nomineArea, uint128 _nomineNumber) public {
        _addNomine(_address, _addharCard, _nomineArea, _nomineNumber);
    }
    
    function _addNomine(address _address, string memory _addharCard, string memory _nomineArea, uint128 _nomineNumber) private isNotNominee(_address) onlyOwner(){
        nomine.add(_address, _addharCard, _nomineArea);
        nomineNumber[_address] = _nomineNumber;
        nomineAddress[_nomineNumber] = _address;
        // nomineVotes[_address] = 0;
        emit nomineAdded(_address);
    }
    
    function removeNomine(address _address) public {
        _removeNomine(_address);
    }
    
    function _removeNomine(address _address) private isAlreadyNominee(_address) onlyOwner(){
        nomine.remove(_address);
        nomineRemoved(_address);
    }
    
    function getNomineNumber(address _address) public view returns(uint128) {
        return nomineNumber[_address];
    }
    
    function getNomineAddress(uint128 _number) public view returns(address) {
        return nomineAddress[_number];
    }
    
    function getNomineArea(address _address) public view returns(string memory) {
        return nomine.getArea(_address);
    }

}
