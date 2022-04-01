pragma solidity ^0.4.11;


import "./Owned.sol";


/**
 * Modular contract modifier that allows only trusted external modules to
 * interact with the contract's functionality.
 */
contract Modular is Owned {
  /**
   * List of modules that can interact with the Modular contract
   */
  mapping (address => bool) public modules;


  /**
   * Sets the owner of the contract as a module
   */
  function Modular() {
    modules[msg.sender] = true;
  }


  /**
   * Set the activation status for a module at at address _module, showing what
   * contracts can perform balance operations.
   *
   * @param _module The address of the module to be activated
   * @param _active The activation status of the module
   */
  function setModule(address _module, bool _active) onlyOwner returns (bool _success) {
    modules[_module] = _active;
    ModuleSet(_module, _active);
    return true;
  }


  /**
   * Get the activation status of a module
   *
   * @param _module The address of the module
   */
  function getModule(address _module) constant returns (bool _success) {
    return modules[_module];
  }


  /**
   * Allow only modules to work with the token storage
   */
  modifier onlyModule() {
    require(modules[msg.sender] == true);
    _;
  }


  /**
   * Module change events
   */
  event ModuleSet(address indexed _module, bool indexed _active);
}
