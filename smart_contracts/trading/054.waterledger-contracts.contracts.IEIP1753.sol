// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface EIP1753 {
    function grantAuthority(address who) external;

    function revokeAuthority(address who) external;

    function hasAuthority(address who) external pure returns (bool);

    function issue(
        address who,
        bytes32 identifier,
        uint256 from,
        uint256 to
    ) external;

    function revoke(address who) external;

    function hasValid(address who) external view returns (bool);

    function purchase(uint256 validFrom, uint256 validTo) external payable;
}
