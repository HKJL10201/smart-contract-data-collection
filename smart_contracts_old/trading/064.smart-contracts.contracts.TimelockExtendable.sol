// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./utils/wrapper/SafeERC20.sol";
import "./utils/upgradeability//Initializable.sol";
import "./utils/Ownable.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 *
 * For a more complete vesting schedule, see {TokenVesting}.
 */
contract TimelockExtendable is Initializable, Ownable {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    function initialize(
        IERC20 token,
        address beneficiary,
        uint256 releaseTime,
        address owner
    ) public initializer {
        require(
            releaseTime > block.timestamp,
            "TokenTimelock: release time is before current time"
        );
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
        //init the owner
        Ownable._onInitialize(owner);
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual onlyOwner {
        _release();
    }

    function releaseAndExtend(uint256 newReleaseTime) public virtual onlyOwner {
        require(
            block.timestamp >= _releaseTime,
            "TokenTimelock: current time is before release time"
        );
        require(
            newReleaseTime > block.timestamp,
            "TokenTimelock: release time is before current time"
        );
        _release();
        _releaseTime = newReleaseTime;
    }

    function _release() internal onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(
            block.timestamp >= _releaseTime,
            "TokenTimelock: current time is before release time"
        );

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.safeTransfer(_beneficiary, amount);
    }
}
