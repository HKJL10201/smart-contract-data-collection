// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./UrlLibrary.sol";

contract URLLibrarayTest {
    using UrlLibrary for UrlLibrary.Url;

    function getBytes(string memory s) public pure returns (bytes memory) {
        return bytes(s);
    }

    function validate(UrlLibrary.Url memory url)
        public
        pure
        returns (bool, string memory)
    {
        return url.validate();
    }
}
