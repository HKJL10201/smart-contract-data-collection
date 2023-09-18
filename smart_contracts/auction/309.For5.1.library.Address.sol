// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @dev 地址类型相关函数的集合
library Address {
// @dev 如果'account'是一个合约返回true。
/* [IMPORTANT]
    * ====
    * 如果此函数返回的结果是false, 则表明输入地址是一个外部个人用户地址(externally-owned account, EOA)而不是一个合约地址, 表明目前的状态是不安全的
    *
    * 在以下这些其他情况下, 函数也可能会返回false:
    *
    * - 外部拥有的帐户
    * - 一个在建设中的合约
    * - 创建合约的地址
    * - 已经被销毁的合约地址
    * ====
*/

    // @notice 函数, 用于判断输入的地址(account)是不是合约
    // -- 此方法依赖于extcodesize，对于构造中的合约, 它返回0, 因为代码仅存储在构造函数执行结束时。
    // @param 输入的地址
    // @return 返回结果如果为true, 则表明'account'是一个合约; 反之则是不安全的
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // @notice 函数, 替代Solidity的'transfer'函数, 发送'amount'数量的wei给'receiver', 转发所有可用的gas并在错误时恢复.
    // @param recipient 接收者地址
    // @param amount 发送的wei的数量
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    // @notice 函数, 真不知为何写这个函数, 应该也是处于安全性 
    /* -- 原话: Performs a Solidity function call using a low level `call`.   
                A plain `call` is an unsafe replacement for a function call: use this function instead. */
    // -- 'target' 必须是一个合约
    // -- 该操作是不可逆的
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    // @notice 函数, 增加报错返回信息
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    // @notice 函数, 增加transfer方法发送的值
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    // @notice 函数, 当'target'返回时，使用'errorMessage'作为回退信息
    // @param target 一个合约的地址
    // @param data 调用时传入的数据
    // @param value 'transfer'的值
    // @param errorMessage 调用失败, 返回的信息
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    // @notice 函数, 也是call, 但是是静态的(多一个'view')
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    // @notice 函数, 和上面一样, 不注释了
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    // @notice 函数, 但这个call是删除指令
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    // @notice 函数, 删除指令的套壳, 加了调用失败的回退信息
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    // @notice 函数, 检验call的结果(用于和各种Call方法关联在一起使用)
    // @param returndata 调用成功时返回的数据
    // @param errorMessage 调用失败的报错信息
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } 
        else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } 
            else {
                revert(errorMessage);
            }
        }
    }
}