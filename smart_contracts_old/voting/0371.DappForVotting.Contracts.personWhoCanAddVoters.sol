//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./Roles.sol";

contract PersonWhoCanAdd {
    using Roles for Roles.ForAdding;

    address private _owner;
    Roles.ForAdding private forAdding;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        _owner = msg.sender;
        _;
    }

    modifier isPersonEligibleForAddingVoter(address _account) {
        require(forAdding.canPersonAddVoter[_account]);
        _;
    }

    modifier isPersonEligibleForAddingNominee(address _account) {
        require(forAdding.canPersonAddNominee[_account]);
        _;
    }

    function destoryContract() public onlyOwner {
        selfdestruct(msg.sender);
    }

    // for adding

    function addPersonForVoter(address _account) public onlyOwner {
        _addPersonForVoter(_account);
    }

    function addPersonForNominee(address _account) public onlyOwner {
        _addPersonForNominee(_account);
    }

    function addPersonNominee(address _account)
        public
        isPersonEligibleForAddingVoter(_account)
    {
        //who is not owner but added by owner
        _addPersonForNominee(_account);
    }

    function addPersonVoter(address _account)
        public
        isPersonEligibleForAddingNominee(_account)
    {
        //who is not owner but added by owner
        _addPersonForVoter(_account);
    }

    // for removing

    function removePersonForVoter(address _account) public onlyOwner {
        _removePersonForVoter(_account);
    }

    function removePersonForNominee(address _account) public onlyOwner {
        _removePersonForNominee(_account);
    }

    function removePersonNominee(address _account)
        public
        isPersonEligibleForAddingVoter(_account)
    {
        //who is not owner but added by owner
        require(_owner != _account);
        _removePersonForNominee(_account);
    }

    function removePersonVoter(address _account)
        public
        isPersonEligibleForAddingNominee(_account)
    {
        //who is not owner but added by owner
        require(_owner != _account);
        _removePersonForVoter(_account);
    }

    // private

    function _addPersonForVoter(address _account) private {
        forAdding.addForVoter(_account);
    }

    function _addPersonForNominee(address _account) private {
        forAdding.addForNominee(_account);
    }

    function _removePersonForVoter(address _account) private {
        forAdding.removeForVoter(_account);
    }

    function _removePersonForNominee(address _account) private {
        forAdding.removeForNominee(_account);
    }
}
