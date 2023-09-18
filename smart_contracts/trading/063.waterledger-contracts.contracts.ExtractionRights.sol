// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEIP1753.sol";
import "./OrderBook.sol";

contract ExtractionRights is Ownable {
    string public name = "Water Ledger ExtractionRights";

    mapping(address => bool) private _authorities;

    struct ExtractionRight {
        bool extractionRightExists;
        bytes32 identifier;
        address ethAccount;
        uint256 validFrom;
        uint256 validTo;
        bytes32[] waterAccountIds;
        mapping(bytes32 => WaterAccount) waterAccounts;
    }

    struct WaterAccount {
        bytes32 waterAccountId;
        bytes32 level0ResourceIdentifier;
    }

    mapping(bytes32 => ExtractionRight) public _extractionRights;
    mapping(address => bytes32) public _addressToIdentifier;
    mapping(bytes32 => bytes32) public _waterAccountIdToIdentifier;
    mapping(address => mapping(bytes32 => bytes32)) public _addressToLevel0ResourceToWaterAccountId;

    OrderBook private immutable _orderbook;

    constructor(address orderbook) Ownable() {
        _authorities[msg.sender] = true;
        _orderbook = OrderBook(orderbook);
    }

    function grantAuthority(address who) public onlyOwner {
        _authorities[who] = true;
    }

    function revokeAuthority(address who) public onlyOwner {
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
        _extractionRights[identifier].identifier = identifier;
        _extractionRights[identifier].extractionRightExists = true;
        _extractionRights[identifier].identifier = identifier;
        _extractionRights[identifier].ethAccount = who;
        _extractionRights[identifier].validFrom = from;
        _extractionRights[identifier].validTo = to;

        _addressToIdentifier[who] = identifier;

        _orderbook.triggerExtractionRightAdded(identifier, who);
    }

    function revoke(address who) public onlyAuthority {
        _extractionRights[_addressToIdentifier[who]].extractionRightExists = false;
        _extractionRights[_addressToIdentifier[who]].identifier = "";
    }

    function getExtractionRight(bytes32 identifier)
        public
        view
        returns (
            address,
            bytes32,
            bytes32[] memory
        )
    {
        ExtractionRight storage extractionRight = _extractionRights[identifier];
        return (extractionRight.ethAccount, extractionRight.identifier, extractionRight.waterAccountIds);
    }

    function isValid(bytes32 identifier) public view returns (bool) {
        return checkValidity(_extractionRights[identifier]);
    }

    function hasValid(address who) public view returns (bool) {
        return checkValidity(_extractionRights[_addressToIdentifier[who]]);
    }

    function checkValidity(ExtractionRight storage extractionRight) internal view returns (bool) {
        return extractionRight.extractionRightExists && block.timestamp >= extractionRight.validFrom && block.timestamp <= extractionRight.validTo;
    }

    function addExtractionRightWaterAccount(
        bytes32 identifier,
        bytes32 waterAccountId,
        bytes32 level0ResourceIdentifier
    ) public onlyAuthority {
        _extractionRights[identifier].waterAccounts[waterAccountId] = WaterAccount(waterAccountId, level0ResourceIdentifier);
        _extractionRights[identifier].waterAccountIds.push(waterAccountId);
        _waterAccountIdToIdentifier[waterAccountId] = identifier;
        _addressToLevel0ResourceToWaterAccountId[_extractionRights[identifier].ethAccount][level0ResourceIdentifier] = waterAccountId;
        _orderbook.triggerWaterAccountAdded(identifier, _extractionRights[identifier].ethAccount);
    }

    function addAllExtractionRightWaterAccounts(
        bytes32 identifier,
        bytes32[] memory waterAccountIds,
        bytes32[] memory level0ResourceIdentifiers
    ) public onlyAuthority {
        require(waterAccountIds.length == level0ResourceIdentifiers.length, "Input arrays must be the same length");

        ExtractionRight storage extractionRight = _extractionRights[identifier];
        for (uint8 i = 0; i < waterAccountIds.length; i++) {
            extractionRight.waterAccounts[waterAccountIds[i]] = WaterAccount(waterAccountIds[i], level0ResourceIdentifiers[i]);
            extractionRight.waterAccountIds.push(waterAccountIds[i]);
            _waterAccountIdToIdentifier[waterAccountIds[i]] = identifier;
            _addressToLevel0ResourceToWaterAccountId[extractionRight.ethAccount][level0ResourceIdentifiers[i]] = waterAccountIds[i];
        }
        _orderbook.triggerExtractionRightCompleted(identifier, extractionRight.ethAccount);
    }

    function purchase() public payable {
        revert("Extraction right purchase is not supported");
    }

    function getWaterAccountIds(bytes32 identifier) public view returns (bytes32[] memory) {
        return _extractionRights[identifier].waterAccountIds;
    }

    function getWaterAccountForWaterAccountId(bytes32 waterAccountId) public view returns (WaterAccount memory) {
        return _extractionRights[_waterAccountIdToIdentifier[waterAccountId]].waterAccounts[waterAccountId];
    }

    function getIdentifierForWaterAccountId(bytes32 waterAccountId) public view returns (bytes32) {
        require(_waterAccountIdToIdentifier[waterAccountId] != "", "There is no matching water account id");
        return _waterAccountIdToIdentifier[waterAccountId];
    }

    function getWaterAccountsForExtractionRight(bytes32 identifier) public view returns (WaterAccount[] memory) {
        uint256 waterAccountsLength = _extractionRights[identifier].waterAccountIds.length;
        require(waterAccountsLength > 0, "There are no water accounts for this extraction right");

        WaterAccount[] memory waterAccountArray = new WaterAccount[](waterAccountsLength);

        for (uint256 i = 0; i < waterAccountsLength; i++) {
            waterAccountArray[i] = _extractionRights[identifier].waterAccounts[_extractionRights[identifier].waterAccountIds[i]];
        }

        return waterAccountArray;
    }

    function getWaterAccountIdByAddressAndLevel0Resource(address ethAccount, bytes32 level0ResourceIdentifier) public view returns (bytes32) {
        return _addressToLevel0ResourceToWaterAccountId[ethAccount][level0ResourceIdentifier];
    }

    modifier onlyAuthority() {
        require(hasAuthority(msg.sender), "Only an authority can perform this function");
        _;
    }
}
