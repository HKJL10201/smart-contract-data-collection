pragma solidity ^0.5.2;


library ToAddress {
    function toAddr(uint _source) internal pure returns(address payable) {
        return address(_source);
    }

    function toAddr(bytes memory _source) internal pure returns(address payable addr) {
        // solium-disable security/no-inline-assembly
        assembly { addr := mload(add(_source,0x14)) }
        return addr;
    }

    function isNotContract(address addr) internal view returns(bool) {
        // solium-disable security/no-inline-assembly
        uint256 length;
        assembly { length := extcodesize(addr) }
        return length == 0;
    }
}
