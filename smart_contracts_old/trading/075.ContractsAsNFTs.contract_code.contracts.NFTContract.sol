// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.4.22 <0.9.0;

abstract contract NFTContract {
    function changeHandlerContract(address newHandlerContract) external virtual;

    function transferOwnership(address newOwner) external virtual;

    function getOwner() public view virtual returns(address);
    
    function getHandlerContract() public view virtual returns(address);
}