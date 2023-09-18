// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Address.sol';
import '../interface/IERC20.sol';
/**
 * @title SafeERC20
 * @dev 围绕ERC20操作的包装，这些操作在失败时抛出(当令牌合约返回false时). 还支持不返回值的令牌(在失败时进行恢复或抛出), 假定非恢复调用是成功的.
 * -- 要使用这个库，你可以在你的合同中添加“using SafeERC20 for IERC20;”语句.
 * -- 允许你调用安全操作，如' token.safeTransfer(…)', 等等.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    // @notice 模拟Solidity高级调用(即对合约的常规函数调用), 放松对返回值的要求: 返回值是可选的(但如果返回数据，则不能为false).
    // @param token 使用代币的IERC20合约
    // @param data 调用时传递的api信息
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
    /* 我们需要在这里执行一个低级调用, 以绕过Solidity的返回数据大小检查机制, 因为我们自己实现了它.
       我们使用 {Address.  functionCall} 来执行此调用, 它验证目标地址是否包含契约代码, 并断言低级调用是否成功. */
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}