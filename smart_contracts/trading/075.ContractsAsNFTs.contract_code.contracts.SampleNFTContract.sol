// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8;

contract SampleNFTContract {
    address private owner;
    address private handlerContract;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier isAuthorized() {
        require(msg.sender == owner || msg.sender == handlerContract, "Unauthorized access");
        _;
    }

    function changeHandlerContract(address newHandler) external isAuthorized {
        handlerContract = newHandler;
    }

    function transferOwnership(address newOwner) external isAuthorized {
        owner = newOwner;
    }

    function getOwner() public view virtual returns(address) {
        return owner;
    }
    
    function getHandlerContract() public view virtual returns(address) {
        return handlerContract;
    }
}
