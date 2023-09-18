// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ApesRandomizer is Ownable {
    mapping(address => bool) public isOperator;

    constructor() {}

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not authorised");
        _;
    }

    function encode(uint256[] calldata _uints)
        external
        view
        onlyOperator
        returns (bytes memory)
    {
        return (abi.encode(_uints));
    }

    function getRandom(bytes memory data, uint256 amount)
        external
        view
        onlyOperator
        returns (uint256[] memory numbers, bool hasExtra)
    {
        uint256[] memory result = abi.decode(data, (uint256[]));

        numbers = new uint256[](amount);
        uint256 available = result.length;

        for (uint256 i = 1; i <= amount; i++) {
            uint256 randomNum = random(i) % available;

            numbers[i - 1] = result[randomNum];

            if (result[randomNum] > 39 && result[randomNum] < 44) {
                // Number between 40 - 43, breeding replenishment
                hasExtra = true;
            }

            result[randomNum] = result[result.length - i];

            available--;
        }
    }

    function setOperator(address operator, bool status) external onlyOwner {
        isOperator[operator] = status;
    }

    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.timestamp,
                        gasleft(),
                        tx.origin
                    )
                )
            );
    }
}
