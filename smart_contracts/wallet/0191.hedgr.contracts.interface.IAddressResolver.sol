pragma solidity 0.5.15;

contract IAddressResolver {
    function getAddress(bytes32 name) public view returns (address);
}