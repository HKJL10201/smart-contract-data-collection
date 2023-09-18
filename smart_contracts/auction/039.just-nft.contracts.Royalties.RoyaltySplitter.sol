// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RoyaltySplitter {
    event RoyaltyReceived(address from, uint256 amount);
    using SafeERC20 for IERC20;
    address payable private immutable _author;
    address payable private immutable _project;
    uint256 private constant AUTOPAY_MIN_GAS = 10_000;

    receive() external payable {
        emit RoyaltyReceived(msg.sender, msg.value);
        if (gasleft() < AUTOPAY_MIN_GAS) return;
        _autoPay();
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        emit RoyaltyReceived(msg.sender, msg.value);
        if (gasleft() < AUTOPAY_MIN_GAS) return;
        _autoPay();
    }

    constructor(address author, address project) {
        _author = payable(author);
        _project = payable(project);
    }

    function _autoPay() private {
        uint256 amount = msg.value / 2;
        _project.transfer(amount);
        _author.transfer(amount);
    }

    function getRoyalties() public {
        require(
            msg.sender == _author || msg.sender == _project,
            "No Authorized"
        );
        uint256 amount = address(this).balance / 2;
        (bool successProject, ) = _project.call{value: amount}(""); // solhint-disable-line avoid-low-level-calls
        (bool successAuthor, ) = _author.call{value: amount}(""); // solhint-disable-line avoid-low-level-calls
        require(successProject && successAuthor, "Transfer Failed");
    }

    function getRoyaltiesToken(IERC20 token) public {
        require(
            msg.sender == _author || msg.sender == _project,
            "No Authorized"
        );
        uint256 amount = token.balanceOf(address(this)) / 2;
        token.safeTransfer(_project, amount);
        token.safeTransfer(_author, amount);
    }

    function showPendingRoyalties() public view returns (uint256) {
        return address(this).balance;
    }
}
