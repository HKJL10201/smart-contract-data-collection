//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AMMExchange {
    using SafeERC20 for IERC20;

    IERC20 public immutable TWD;
    IERC20 public immutable USD;

    uint256 public Rt; // TWD reserve
    uint256 public Ru; // USD reserve

    event AddLiquidity(
        address indexed LP,
        uint256 indexed twd,
        uint256 indexed usd
    );

    event Exchange(
        address indexed sender,
        address indexed tradedToken,
        uint256 indexed tradedAmount
    );

    event UpdateReserves(
        uint256 oldRu,
        uint256 newRu,
        uint256 oldRt,
        uint256 newRt
    );

    constructor(IERC20 _twd, IERC20 _usd) {
        TWD = _twd;
        USD = _usd;
    }

    function addLiquidity(uint256 _twd, uint256 _usd) external {
        _safeTransferFrom(TWD, msg.sender, address(this), _twd);
        _safeTransferFrom(USD, msg.sender, address(this), _usd);

        _updateReserves(int256(_twd), int256(_usd));

        emit AddLiquidity(msg.sender, _twd, _usd);
    }

    function exchange(uint256 amount, IERC20[] memory path) external {
        require(
            path.length == 2 &&
                address(path[0]) != address(0) &&
                address(path[1]) != address(0) &&
                _validPath(path),
            "AMMExchange: invalid path"
        );

        IERC20 inputToken = path[0];
        IERC20 outputToken = path[1];

        int256 outputAmount = _exchange(
            inputToken,
            outputToken,
            amount,
            Rt,
            Ru
        );

        if (inputToken == TWD) {
            _updateReserves(int256(amount), outputAmount);
        } else {
            _updateReserves(outputAmount, int256(amount));
        }

        emit Exchange(msg.sender, address(inputToken), amount);
    }

    function _exchange(
        IERC20 inputToken,
        IERC20 outputToken,
        uint256 inputAmount,
        uint256 reserveTWD,
        uint256 reserveUSD
    ) internal returns (int256) {
        require(
            _sufficientAllowance(
                inputToken,
                inputAmount,
                msg.sender,
                address(this)
            ),
            "AMMExchange: insufficient inputToken allowance"
        );

        require(
            _sufficientBalance(inputToken, inputAmount, msg.sender),
            "AMMExchange: insufficient inputToken balance"
        );

        int256 outputAmount = _getAmountOut(
            int256(inputAmount),
            int256(reserveTWD),
            int256(reserveUSD)
        );
        uint256 outputAmount_uint256 = uint256(-outputAmount);

        require(
            _sufficientBalance(
                outputToken,
                outputAmount_uint256,
                address(this)
            ),
            "AMMExchange: insufficient onputToken balance"
        );

        _safeTransferFrom(inputToken, msg.sender, address(this), inputAmount);
        outputToken.transfer(msg.sender, outputAmount_uint256);

        return outputAmount;
    }

    function _getAmountOut(
        int256 inputAmount,
        int256 rt,
        int256 ru
    ) internal pure returns (int256 outAmount) {
        outAmount = ((rt * ru) / (rt + inputAmount)) - ru;
    }

    function _safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        token.transferFrom(from, to, amount);
    }

    function _sufficientAllowance(
        IERC20 token,
        uint256 amount,
        address owner,
        address spender
    ) internal view returns (bool) {
        return token.allowance(owner, spender) >= amount;
    }

    function _sufficientBalance(
        IERC20 token,
        uint256 amount,
        address account
    ) internal view returns (bool) {
        return token.balanceOf(account) >= amount;
    }

    function _updateReserves(int256 rt, int256 ru) internal {
        uint256 oldRu = Ru;
        uint256 oldRt = Rt;

        uint256 newRu = uint256(int256(oldRu) + ru);
        uint256 newRt = uint256(int256(oldRt) + rt);

        Ru = newRu;
        Rt = newRt;

        emit UpdateReserves(oldRu, newRu, oldRt, newRt);
    }

    function _validPath(IERC20[] memory path) public view returns (bool) {
        IERC20 TWD_ = TWD;
        IERC20 USD_ = USD;

        if (
            (path[0] == TWD_ && path[1] == USD_) ||
            (path[0] == USD_ && path[1] == TWD_)
        ) {
            return true;
        }

        return false;
    }

    function getReserves() public view returns (uint256 ru, uint256 rt) {
        ru = Ru;
        rt = Rt;
    }
}
