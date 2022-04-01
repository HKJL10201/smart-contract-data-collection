pragma solidity ^0.4.23;

library MemArrApp {

    // A simple library to allow appending to memory arrays.

    function appendUint256(uint256[] memory arr, uint256 val) internal pure returns (uint256[] memory toRet) {
        toRet = new uint256[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendUint128(uint128[] memory arr, uint128 val) internal pure returns (uint128[] memory toRet) {
        toRet = new uint128[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendUint64(uint64[] memory arr, uint64 val) internal pure returns (uint64[] memory toRet) {
        toRet = new uint64[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendUint32(uint32[] memory arr, uint32 val) internal pure returns (uint32[] memory toRet) {
        toRet = new uint32[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendUint16(uint16[] memory arr, uint16 val) internal pure returns (uint16[] memory toRet) {
        toRet = new uint16[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendBool(bool[] memory arr, bool val) internal pure returns (bool[] memory toRet) {
        toRet = new bool[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendBytes32(bytes32[] memory arr, bytes32 val) internal pure returns (bytes32[] memory toRet) {
        toRet = new bytes32[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendBytes32Pair(bytes32[2][] memory arr, bytes32[2] val) internal pure returns (bytes32[2][] memory toRet) {
        toRet = new bytes32[2][](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendBytes(bytes[] memory arr, bytes val) internal pure returns (bytes[] memory toRet) {
        toRet = new bytes[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

    function appendAddress(address[] memory arr, address val) internal pure returns (address[] memory toRet) {
        toRet = new address[](arr.length + 1);

        for (uint256 i = 0; i < arr.length; i++) {
            toRet[i] = arr[i];
        }

        toRet[arr.length] = val;
    }

}
