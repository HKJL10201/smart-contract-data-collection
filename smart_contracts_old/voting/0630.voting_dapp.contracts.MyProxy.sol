// SPDX-License-Identifier: AGPL-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MyProxy is ERC1967Proxy {
    constructor(address implementation, address, bytes memory data)
    ERC1967Proxy(implementation, data) {}
}