// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./UrlLibrary.sol";
import "./UrlDatabase.sol";

contract UrlDatabaseTest is UrlDatabase {
    function urlIdTest(UrlLibrary.Url memory url)
        public
        pure
        returns (bytes32)
    {
        return getUrlId(url);
    }

    function keywordsIdTest(string[] memory keywords)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(keywords));
    }
}
