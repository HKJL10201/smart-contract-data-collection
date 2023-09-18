// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Fund.sol";

contract FundFactory {
    mapping(string => address) public getFundByName;
    mapping(string => address) public getFundBySymbol;

    // TODO: maybe want to change this to a struct with tokens and qty for each fund
    address[] public allFunds;
    string[] public allFundNames;
    address public routerAddress;

    event FundCreated(address fund, string name, string symbol);

    constructor(address _routerAddress) {
        routerAddress = _routerAddress;
    }

    function allFundsLength() external view returns (uint256) {
        return allFunds.length;
    }

    function getAllFunds() external view returns (address[] memory) {
        return allFunds;
    }

    function getAllFundNames() external view returns (string[] memory) {
        return allFundNames;
    }

    function createFund(
        string memory _name,
        string memory _symbol,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external returns (address fund) {
        require(
            _tokens.length == _amounts.length,
            "incorrect number of assets and quantities"
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), "zero address");
            require(_amounts[i] != 0, "no quantity");
        }
        require(getFundByName[_name] == address(0), "fund name exists");
        require(getFundBySymbol[_symbol] == address(0), "fund symbol exists");
        Fund newFund = new Fund(
            _name,
            _symbol,
            routerAddress,
            _tokens,
            _amounts
        );

        getFundByName[_name] = address(newFund);
        getFundBySymbol[_symbol] = address(newFund);
        allFunds.push(address(newFund));
        allFundNames.push(_name);
        emit FundCreated(address(newFund), _name, _symbol);
    }


}
