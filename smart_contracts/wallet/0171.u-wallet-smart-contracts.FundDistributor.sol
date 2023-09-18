// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FundDistributor is AccessControl {

    ERC20 public token;

    uint256 maxLimit = 20_000_000_000_000;

    mapping(address => Participant) public participants;

    event UserHasBeenAdded(address user);

    constructor(address _Token) {
        token = ERC20(_Token);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    struct Participant {
        uint256 currentLimit;
        uint256 currentlyOwed;
        uint256 nextAllowedWithdrawBlock;
    }

    function addAdress(address user) external payable {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not administrator");

        (bool isSuccess, ) = user.call{value: msg.value}("");
        require(isSuccess, "failed to transfer gas to the user");

        participants[user] = Participant({
            nextAllowedWithdrawBlock: block.number,
            currentlyOwed: 0,
            currentLimit: maxLimit
        });

        emit UserHasBeenAdded(user);
    }

    function hasParticipant(address user) public view returns(bool) {
        return participants[user].currentLimit != 0;
    }

    function amountAvailable(address user) public view returns(uint256) {
        return participants[user].currentLimit - participants[user].currentlyOwed;
    }

    function withdraw(uint256 amount) public {
        uint256 balance = token.balanceOf(address(this));
        require(balance > amount, "not enough funds in contract");

        Participant memory user = participants[msg.sender];
        require(user.nextAllowedWithdrawBlock < block.number, "caller is not eligible for next withdraw");
        require(user.currentLimit > amount, "caller is not eligible for withdraw amount");
        require(user.currentlyOwed < user.currentLimit - amount, "caller is not eligible for withdraw amount");
        require(token.transfer(msg.sender, amount), "withdraw failed");
        
        user.currentlyOwed += amount;
        user.nextAllowedWithdrawBlock += block.number + 67280;
    }

    function repay(uint256 amount) public {
        require(token.transferFrom(msg.sender, address(this), amount), "failed to repay");

        participants[msg.sender].currentlyOwed -= amount;

        uint256 owed = participants[msg.sender].currentlyOwed;
        if (amount < owed) {
            return;
        }

        uint256 newLimit = participants[msg.sender].currentLimit * 105 / 100;

        if ( newLimit > maxLimit ) {
            newLimit = maxLimit;
        }

        participants[msg.sender].currentLimit = newLimit;
    }

    function withdrawToken(uint256 _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not administrator");
        token.transfer(msg.sender, _amount);
    }
}
