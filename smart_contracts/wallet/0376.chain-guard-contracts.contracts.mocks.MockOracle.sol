pragma solidity 0.8.12;

import "../interfaces/IOracle.sol";

contract MockOracle is IOracle {
    uint256 public immutable price;

    constructor(uint256 _price) {
        price = _price;
    }

    function getEthPrice() external view override returns (uint256) {
        return price;
    }
}
