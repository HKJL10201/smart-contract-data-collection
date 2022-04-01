pragma solidity >=0.5.0 <=0.5.17;

import "./Allowance.sol";

contract SharedWallet is Allowance {
    function withdrawMoney(address payable _to, uint256 _amount)
        public
        ownerOrAllowed(_amount)
    {
        require(
            _amount <= address(this).balance,
            "There are not enough funds stored in the smart contract."
        );
        if (!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        _to.transfer(_amount);
    }

    function renounceOwnership() public onlyOwner {
        revert("Can't renounce ownership here.");
    }

    function() external payable {}
}
