pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;
  address private _admin;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  event AdministrationTransferred(
    address indexed previousAdmin,
    address indexed newAdmin
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @return the address of the admin.
   */
  function admin() public view returns(address) {
    return _admin;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyAdmin() {
    require(isAdmin());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @return true if `msg.sender` is the admin of the contract.
   */
  function isAdmin() public view returns(bool) {
    return msg.sender == _admin;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  /**
   * @dev Allows the current owner to transfer admin control of the contract to a newAdmin.
   * @param newAdmin The address to transfer admin powers to.
   */
  function transferAdministration(address newAdmin) public onlyOwner {
    _transferAdministration(newAdmin);
  }

  /**
   * @dev Transfers admin control of the contract to a newAdmin.
   * @param newAdmin The address to transfer admin power to.
   */
  function _transferAdministration(address newAdmin) internal {
    require(newAdmin != address(0));
    require(newAdmin != address(this));
    emit AdministrationTransferred(_admin, newAdmin);
    _admin = newAdmin;
  }

}