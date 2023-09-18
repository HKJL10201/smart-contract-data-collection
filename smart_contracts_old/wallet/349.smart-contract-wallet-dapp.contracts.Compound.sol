pragma solidity ^0.7.3;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CTokenInterface.sol";
import "./CEthInterface.sol";
import "./ComptrollerInterface.sol";

contract Compound {
    ComptrollerInterface public comptroller;
    CEthInterface public cEth;

    constructor(address _comptroller, address _cEthAddress) {
        comptroller = ComptrollerInterface(_comptroller);
        cEth = CEthInterface(_cEthAddress);
    }

    function supply(address cTokenAddress, uint256 underlyingAmount) internal {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        address underlyingAddress = cToken.underlying();
        IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
        uint256 result = cToken.mint(underlyingAmount);
        require(result == 0, "cToken#mint failed");
    }

    function supplyEth(uint256 underlyingAmount) internal {
        cEth.mint{value: underlyingAmount}();
    }

    function redeem(address cTokenAddress, uint256 underlyingAmount) internal {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        uint256 result = cToken.redeemUnderlying(underlyingAmount);
        require(result == 0, "CToken#redeemUnderlying() failed");
    }

    function redeemEth(uint256 underlyingAmount) internal view {
        uint256 result = cEth.redeemUnderlying(underlyingAmount);
        require(result == 0, "cEth#redeemUnderlying()failed");
    }

    function claimComp() internal {
        comptroller.claimComp(address(this));
    }

    function getCompAddress() internal view returns (address) {
        return comptroller.getCompAddress();
    }

    function getUnderlyingAddress(address cTokenAddress)
        internal
        view
        returns (address)
    {
        return CTokenInterface(cTokenAddress).underlying();
    }

    function getcTokenBalance(address cTokenAddress)
        public
        view
        returns (uint256)
    {
        return CTokenInterface(cTokenAddress).balanceOf(address(this));
    }

    function getUnderlyingBalance(address cTokenAddress)
        public
        returns (uint256)
    {
        return
            CTokenInterface(cTokenAddress).balanceOfUnderlying(address(this));
    }

    function getUnderlyingEthBalance() public returns (uint256) {
        return cEth.balanceOfUnderlying(address(this));
    }
}
