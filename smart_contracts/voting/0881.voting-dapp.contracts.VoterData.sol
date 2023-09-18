// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract VoterData {
    mapping(string => bool) public voterID;
    mapping(string => bool) public addressInUse;

    constructor() public {}

    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }

    event registrationDone(bool data);

    function registerNewVoter(string calldata id, string calldata add) public {
        require(!voterID[id], "Voter already registered");

        voterID[id] = true;
        addressInUse[lower(add)] = true;

        emit registrationDone(true);
    }

    function isAddressInUse(string calldata add) external view returns (bool) {
        return addressInUse[lower(add)] ? true : false;
    }
}
