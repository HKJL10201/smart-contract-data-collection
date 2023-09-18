pragma solidity ^0.5.1;


import "../Address.sol";


contract TestAddress {
    using ToAddress for *;

    function bytesToAddr(bytes memory _source) public pure returns(address addr) {
        return _source.toAddr();
    }

    function isNotContract(address addr) public view returns(bool) {
        return addr.isNotContract();
    }
}
