pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract ShareStaking is ERC20("My Token Share", "xERC20") {
    using SafeMath for uint256;
    IERC20 public token;

    constructor(IERC20 _token) public {
        token = _token;
    }

    // Enter the Staking Bar. Pay some tokens. Earn some token shares.
    function enter(uint256 _amount) public {
        uint256 totaltoken = token.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totaltoken == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totaltoken);
            _mint(msg.sender, what);
        }
        token.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your tokens.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(token.balanceOf(address(this))).div(
            totalShares
        );
        _burn(msg.sender, _share);
        token.transfer(msg.sender, what);
    }
}
