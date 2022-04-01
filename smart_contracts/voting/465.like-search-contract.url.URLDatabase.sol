// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./UrlLibrary.sol";

contract UrlDatabase {
    using UrlLibrary for UrlLibrary.Url;
    mapping(bytes32 => UrlLibrary.Url) urls;
    event UrlSaved(bytes32 indexed id);

    function saveUrl(UrlLibrary.Url memory url) internal returns (bytes32) {
        (bool valid, string memory reason) = url.validate();
        require(valid, reason);
        bytes32 id = getUrlId(url);
        UrlLibrary.Url storage savedUrl = urls[id];
        if (bytes(savedUrl.scheme).length == 0) {
            urls[id] = url;
            emit UrlSaved(id);
        }
        return id;
    }

    function getUrl(bytes32 id) public view returns (UrlLibrary.Url memory) {
        return urls[id];
    }

    function getUrlId(UrlLibrary.Url memory url)
        internal
        pure
        returns (bytes32)
    {
        // abi.encodePacked() is easy to craft collisions,"ab""c"=="a""bc"
        return
            keccak256(
                abi.encode(
                    url.scheme,
                    url.username,
                    url.hostname,
                    url.port,
                    url.pathname,
                    url.search,
                    url.fragment
                )
            );
    }
}
