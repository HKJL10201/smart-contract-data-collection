//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

contract AddressRegistry {
    mapping(uint256 => address) public addresses;
    uint256 public nextId = 0;

    event AddressRegistered(uint256 id, address indexed addr);

    function register(address addr) external {
        uint256 id = nextId;
        nextId += 1;
        addresses[id] = addr;

        emit AddressRegistered(id, addr);
    }

    function lookup(uint256 id) external view returns (address) {
        address addr = addresses[id];
        require(addr != address(0), "AddressRegistry: Address not found");

        return addr;
    }
}
