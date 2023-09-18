// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

interface Callee {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external view returns (bytes4);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external view returns (bytes4);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view returns (bytes4);

    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract TokenCaller {
    function checkERC1155(address _contract) external view returns (bytes4 result) {
        address zero = address(0);
        result = Callee(_contract).onERC1155Received(zero, zero, 0, 0, "0x");
    }

    function checkERC115Batch(address _contract) external view returns (bytes4 result) {
        address zero = address(0);
        uint256[] memory mock = new uint256[](1);
        mock[0] = 0;
        result = Callee(_contract).onERC1155BatchReceived(zero, zero, mock, mock, "0x");
    }

    function checkERC721(address _contract) external view returns (bytes4 result) {
        address zero = address(0);
        result = Callee(_contract).onERC721Received(zero, zero, 0, "0x");
    }

    function checkERC165(address _contract, bytes4 _interfaceId) external view returns (bool result) {
        result = Callee(_contract).supportsInterface(_interfaceId);
    }
}
