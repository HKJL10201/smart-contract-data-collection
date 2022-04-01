// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title Auth Contract
 * @author Beau Williams (@beauwilliams)
 * @dev Smart contract for Auth controls
 */

abstract contract AuthUpgradeable is Initializable, UUPSUpgradeable, ContextUpgradeable {
    address owner;
    mapping (address => bool) private authorisations;

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    function __AuthUpgradeable_init() internal onlyInitializing {
        __AuthUpgradeable_init_unchained();
    }

    /**
    * @dev See: https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance
    */
    function __AuthUpgradeable_init_unchained() internal onlyInitializing {
        //NOTE: We use _msgSender() function to retreive contract owner address because
        //msg.sender variable will refer to the proxy contract address when deploying upgrades
        //the ContextUpgradable dependency is added to import the _msgSender() function
        owner = _msgSender();
        authorisations[_msgSender()] = true;
      __UUPSUpgradeable_init();
    }

    modifier onlyOwner() {
        require(isOwner(_msgSender())); _;
    }

    modifier authorised() {
        require(isAuthorised(_msgSender())); _;
    }

    function authorise(address _address) public onlyOwner {
        authorisations[_address] = true;
        emit Authorised(_address);
    }

    function unauthorise(address _address) public onlyOwner {
        authorisations[_address] = false;
        emit Unauthorised(_address);
    }

    function isOwner(address _address) public view returns (bool) {
        return _address == owner;
    }

    function isAuthorised(address _address) public view returns (bool) {
        return authorisations[_address];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        authorisations[oldOwner] = false;
        authorisations[newOwner] = true;
        emit Unauthorised(oldOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    event OwnershipTransferred(address oldOwner, address newOwner);
    event Authorised(address _address);
    event Unauthorised(address _address);


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
