// SPDX-License-Identifier: MIT
// Project Sharing by Alpha Serpentis Developments - https://github.com/Alpha-Serpentis-Developments
// Written by Amethyst C.

pragma solidity ^0.7.4;

import "./Caring.sol";

contract CaringDeployer {

    address payable private creator;

    uint256 private creatorFee; // Aka the deploying fee, in wei units
    bool private sendDirect;

    modifier onlyCreator {
        if(msg.sender != creator) {
            revert("CaringDeployer: Not the creator!");
        }
        _;
    }
    modifier meetCreatorFee {
        if(msg.value < creatorFee) {
            revert("CaringDeployer: Does not meet the creator fee (service fee)! Call getCreatorFee to check minimum required in wei units.");
        }
        _;
    }

    event CaringIssued(address _caller, address _deployed);

    constructor(uint256 _creatorFee, bool _sendDirect) {
        creator = msg.sender;
        creatorFee = _creatorFee;
        sendDirect = _sendDirect;
    }

    function deployCaringContract(address _manager, uint256 _maxManagers, string memory _contractName, bool _multiSig, uint256 _autoAcceptTimeLength) external payable meetCreatorFee returns(address) {

        address deployed = address(new Caring(_manager, _maxManagers, _contractName, _multiSig, _autoAcceptTimeLength));
        require(deployed != address(0), "CaringDeployer: Contract creation failed!");
        emit CaringIssued(msg.sender, deployed);

        if(sendDirect)
            creator.transfer(msg.value);

        return deployed;
    }
    function redeemFee() public onlyCreator {
        creator.transfer(address(this).balance);
    }

    function setCreatorFee(uint256 _fee) external onlyCreator {
        creatorFee = _fee;
    }

    function getCreatorFee() public view returns(uint256) {
        return creatorFee;
    }
    function getCreator() public view returns(address payable) {
        return creator;
    }

}
