// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
/**
 * @title Auth Contract
 * @author Beau Williams (@beauwilliams)
 * @dev Smart contract for Auth controls
 */

abstract contract Auth {
    address owner;
    mapping (address => bool) private authorisations;

    constructor(address _owner) {
        owner = _owner;
        authorisations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorised() {
        require(isAuthorised(msg.sender)); _;
    }

    function authorise(address adr) public onlyOwner {
        authorisations[adr] = true;
        emit Authorised(adr);
    }

    function unauthorise(address adr) public onlyOwner {
        authorisations[adr] = false;
        emit Unauthorised(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorised(address adr) public view returns (bool) {
        return authorisations[adr];
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
    event Authorised(address adr);
    event Unauthorised(address adr);
}
