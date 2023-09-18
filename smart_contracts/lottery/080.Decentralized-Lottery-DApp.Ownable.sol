// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

abstract contract Ownable {
    // Owner's address
    address private _owner;

    // Ownership transferred event
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner);

    constructor(){
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // Returns address of owner
    function owner() public view returns (address) {
        return _owner;
    }

    // Only owner modifier
    // Throws error if called by any account other than the owner
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    // Returns if msg.sender is owner or not
    function isOwner() public view returns(bool) {
        return msg.sender==_owner;
    }

    // Allows current owner to transfer ownership i.e control over contract 
    // to a new Owner
    // This function can only be called by owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner!=address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;   
    }

    // Allows current user to relinquish control of the contract 
    // Renouncing the ownership will leave the contract without an owner
    // It will not be able to call the functions with the onlyOwner modifier anymore
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}