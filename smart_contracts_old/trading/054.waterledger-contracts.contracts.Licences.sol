// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEIP1753.sol";

contract Licences is Ownable {
    string public name = "Water Ledger Licences";

    mapping(address => bool) private _authorities;

    struct Licence {
        bool licenceExists;
        bytes32 identifier;
        address ethAccount;
        uint256 validFrom;
        uint256 validTo;
        bytes32[] waterAccountIds;
        mapping(bytes32 => WaterAccount) waterAccounts;
    }

    struct WaterAccount {
        bytes32 waterAccountId;
        bytes32 zoneIdentifier;
    }

    mapping(bytes32 => Licence) public _licences;
    mapping(address => bytes32) public _addressToIdentifier;
    mapping(bytes32 => bytes32) public _waterAccountIdToIdentifier;
    mapping(address => mapping(bytes32 => bytes32)) public _addressToZoneToWaterAccountId;

    constructor() Ownable() {
        _authorities[msg.sender] = true;
    }

    function grantAuthority(address who) public onlyOwner() {
        _authorities[who] = true;
    }

    function revokeAuthority(address who) public onlyOwner() {
        _authorities[who] = false;
    }

    function hasAuthority(address who) public view returns (bool) {
        return _authorities[who];
    }

    function issue(
        address who,
        bytes32 identifier,
        uint256 from,
        uint256 to
    ) public onlyAuthority {
        _licences[identifier].identifier = identifier;
        _licences[identifier].licenceExists = true;
        _licences[identifier].identifier = identifier;
        _licences[identifier].ethAccount = who;
        _licences[identifier].validFrom = from;
        _licences[identifier].validTo = to;

        _addressToIdentifier[who] = identifier;

        emit LicenceAdded(identifier, who);
    }

    function revoke(address who) public onlyAuthority() {
        _licences[_addressToIdentifier[who]].licenceExists = false;
        _licences[_addressToIdentifier[who]].identifier = '';
    }

    function getLicence(bytes32 identifier) public view returns (address, bytes32, bytes32[] memory) {
        Licence storage licence = _licences[identifier];
        return (licence.ethAccount, licence.identifier, licence.waterAccountIds);
    }

    function isValid(bytes32 identifier) public view returns (bool) {
        return checkValidity(_licences[identifier]);
    }

    function hasValid(address who) public view returns (bool) {
        return checkValidity(_licences[_addressToIdentifier[who]]);
    }

    function checkValidity(Licence storage licence) internal view returns (bool) {
        return licence.licenceExists && block.timestamp >= licence.validFrom && block.timestamp <= licence.validTo;
    }

    function addLicenceWaterAccount(
        bytes32 identifier,
        bytes32 waterAccountId,
        bytes32 zoneIdentifier
    ) public onlyAuthority {
        _licences[identifier].waterAccounts[waterAccountId] = WaterAccount(waterAccountId, zoneIdentifier);
        _licences[identifier].waterAccountIds.push(waterAccountId);
        _waterAccountIdToIdentifier[waterAccountId] = identifier;
        _addressToZoneToWaterAccountId[_licences[identifier].ethAccount][zoneIdentifier] = waterAccountId;
        emit WaterAccountAdded(identifier, _licences[identifier].ethAccount);
    }

    function addAllLicenceWaterAccounts(
        bytes32 identifier,
        bytes32[] memory waterAccountIds,
        bytes32[] memory zoneIdentifiers
    ) public onlyAuthority {
        require(waterAccountIds.length == zoneIdentifiers.length, "Input arrays must be the same length");

        Licence storage licence = _licences[identifier];
        for (uint8 i = 0; i < waterAccountIds.length; i++) {
            licence.waterAccounts[waterAccountIds[i]] = WaterAccount(waterAccountIds[i], zoneIdentifiers[i]);
            licence.waterAccountIds.push(waterAccountIds[i]);
            _waterAccountIdToIdentifier[waterAccountIds[i]] = identifier;
            _addressToZoneToWaterAccountId[licence.ethAccount][zoneIdentifiers[i]] = waterAccountIds[i];
        }
        emit LicenceCompleted(identifier, licence.ethAccount);
    }

    function purchase() public payable {
        revert("Licence purchase is not supported");
    }

    function getWaterAccountIds(bytes32 identifier) public view returns (bytes32[] memory) {
        return _licences[identifier].waterAccountIds;
    }

    function getWaterAccountForWaterAccountId(bytes32 waterAccountId) public view returns (WaterAccount memory) {
        return _licences[_waterAccountIdToIdentifier[waterAccountId]].waterAccounts[waterAccountId];
    }

    function getIdentifierForWaterAccountId(bytes32 waterAccountId) public view returns (bytes32) {
        require(_waterAccountIdToIdentifier[waterAccountId] != '', 'There is no matching water account id');
        return _waterAccountIdToIdentifier[waterAccountId];
    }

    function getWaterAccountsForLicence(bytes32 identifier) public view returns (WaterAccount[] memory) {
        uint256 waterAccountsLength = _licences[identifier].waterAccountIds.length;
        require(waterAccountsLength > 0, "There are no water accounts for this licence");

        WaterAccount[] memory waterAccountArray = new WaterAccount[](waterAccountsLength);

        for (uint256 i = 0; i < waterAccountsLength; i++) {
            waterAccountArray[i] = _licences[identifier].waterAccounts[_licences[identifier].waterAccountIds[i]];
        }

        return waterAccountArray;
    }

    function getWaterAccountIdByAddressAndZone(address ethAccount, bytes32 zoneIdentifier) public view returns (bytes32) {
        return _addressToZoneToWaterAccountId[ethAccount][zoneIdentifier];
    }

    modifier onlyAuthority() {
        require(hasAuthority(msg.sender), "Only an authority can perform this function");
        _;
    }

    event LicenceAdded(bytes32 indexed identifier, address indexed ethAccount);
    event WaterAccountAdded(bytes32 indexed identifier, address indexed ethAccount);
    event WaterAccountsAdded(bytes32[] identifiers, address[] ethAccount);
    event LicenceCompleted(bytes32 indexed identifier, address indexed ethAccount);
}
