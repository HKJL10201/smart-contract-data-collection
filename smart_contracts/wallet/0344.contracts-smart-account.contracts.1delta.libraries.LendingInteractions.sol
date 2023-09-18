// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;


// assembly library for efficient compound style lending interactions
abstract contract LendingInteractions {
    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    address internal immutable cNative;
    address internal immutable wNative;

    constructor(address _cNative, address _wNative) {
        cNative = _cNative;
        wNative = _wNative;
    }

    function _mint(address cAsset, uint256 amount) internal {
        address _cNative = cNative;
        address _wNative = wNative;
        address _cAsset = cAsset;
        assembly {
            switch eq(_cAsset, _cNative)
            case 1 {
                let ptr := mload(0x40) // free memory pointer
                // selector for withdraw(uint26)
                mstore(ptr, 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x4), amount)

                pop(
                    call(
                        gas(),
                        and(_wNative, ADDRESS_MASK),
                        0x0, // 0 ETH
                        ptr, // input selector
                        0x24, // input size = selector plus uint256
                        0x0, // output
                        0x0 // output size = zero
                    )
                )
                // selector for mint()
                mstore(ptr, 0x1249c58b00000000000000000000000000000000000000000000000000000000)

                let success := call(
                    gas(),
                    and(_cNative, ADDRESS_MASK),
                    amount, // amount in ETH
                    ptr, // input selector
                    0x4, // input size = selector
                    0x0, // output
                    0x0 // output size = zero
                )
                let rdsize := returndatasize()

                if iszero(success) {
                    returndatacopy(ptr, 0, rdsize)
                    revert(ptr, rdsize)
                }
            }
            default {
                let ptr := mload(0x40) // free memory pointer

                // selector for mint(uint256)
                mstore(ptr, 0xa0712d6800000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x4), amount)

                let success := call(
                    gas(),
                    and(_cAsset, ADDRESS_MASK),
                    0x0,
                    ptr, // input = selector and data
                    0x24, // input size = 4 + 32
                    ptr, // output
                    0x0 // output size = zero
                )
                let rdsize := returndatasize()

                if iszero(success) {
                    returndatacopy(ptr, 0, rdsize)
                    revert(ptr, rdsize)
                }
            }
        }
    }

    function _redeemUnderlying(address cAsset, uint256 amount) internal {
        address _cNative = cNative;
        address _wNative = wNative;
        address _cAsset = cAsset;
        assembly {
            switch eq(_cAsset, _cNative)
            case 1 {
                let ptr := mload(0x40) // free memory pointer
                // selector for redeemUnderlying(uint256)
                mstore(ptr, 0x852a12e300000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x4), amount)

                let success := call(
                    gas(),
                    and(_cNative, ADDRESS_MASK),
                    0x0,
                    ptr, // input = selector
                    0x24, // input selector + uint256
                    ptr, // output
                    0x0 // output size = zero
                )
                let rdsize := returndatasize()

                if iszero(success) {
                    returndatacopy(ptr, 0, rdsize)
                    revert(ptr, rdsize)
                }

                // selector for deposit()
                mstore(ptr, 0xd0e30db000000000000000000000000000000000000000000000000000000000)
                pop(
                    call(
                        gas(),
                        and(_wNative, ADDRESS_MASK),
                        amount, // ETH to deposit
                        ptr, // seletor for deposit()
                        0x4, // input size = selector
                        0x0, // output = empty
                        0x0 // output size = zero
                    )
                )
            }
            default {
                let ptr := mload(0x40) // free memory pointer

                // selector for redeemUnderlying(uint256)
                mstore(ptr, 0x852a12e300000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x4), amount)

                let success := call(
                    gas(),
                    and(_cAsset, ADDRESS_MASK),
                    0x0,
                    ptr, // input = empty for fallback
                    0x24, // input size = selector + uint256
                    ptr, // output
                    0x0 // output size = zero
                )
                let rdsize := returndatasize()

                if iszero(success) {
                    returndatacopy(ptr, 0, rdsize)
                    revert(ptr, rdsize)
                }
            }
        }
    }

    function _repayBorrow(address cAsset, uint256 amount) internal {
        address _cNative = cNative;
        address _wNative = wNative;
        address _cAsset = cAsset;
        assembly {
            switch eq(_cAsset, _cNative)
            case 1 {
                let ptr := mload(0x40) // free memory pointer
                // selector for withdraw(uint26)
                mstore(ptr, 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x4), amount)

                pop(
                    call(
                        gas(),
                        and(_wNative, ADDRESS_MASK),
                        0x0, // 0 ETH
                        ptr, // input selector
                        0x24, // input size = selector plus uint256
                        0x0, // output
                        0x0 // output size = zero
                    )
                )
                // selector for repayBorrow()
                mstore(ptr, 0x4e4d9fea00000000000000000000000000000000000000000000000000000000)

                let success := call(
                    gas(),
                    and(_cNative, ADDRESS_MASK),
                    amount,
                    ptr, // input selector
                    0x4, // input size = selector
                    ptr, // output
                    0x0 // output size = zero
                )
                let rdsize := returndatasize()

                if iszero(success) {
                    returndatacopy(ptr, 0, rdsize)
                    revert(ptr, rdsize)
                }
            }
            default {
                let ptr := mload(0x40) // free memory pointer

                // selector for repayBorrow(uint256)
                mstore(ptr, 0x0e75270200000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x4), amount)

                let success := call(
                    gas(),
                    and(_cAsset, ADDRESS_MASK),
                    0x0,
                    ptr, // input = empty for fallback
                    0x24, // input size = zero
                    ptr, // output
                    0x0 // output size = zero
                )
                let rdsize := returndatasize()

                if iszero(success) {
                    returndatacopy(ptr, 0, rdsize)
                    revert(ptr, rdsize)
                }
            }
        }
    }

    function _borrow(address cAsset, uint256 amount) internal {
        address _cNative = cNative;
        address _wNative = wNative;
        address _cAsset = cAsset;
        assembly {
            switch eq(_cAsset, _cNative)
            case 1 {
                let ptr := mload(0x40) // free memory pointer
                // selector for borrow(uint256)
                mstore(ptr, 0xc5ebeaec00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x4), amount)

                let success := call(
                    gas(),
                    and(_cNative, ADDRESS_MASK),
                    0x0, // no ETH sent
                    ptr, // input selector
                    0x24, // input size = selector + uint256
                    ptr, // output
                    0x0 // output size = zero
                )
                let rdsize := returndatasize()

                if iszero(success) {
                    returndatacopy(ptr, 0, rdsize)
                    revert(ptr, rdsize)
                }
                // selector for deposit()
                mstore(ptr, 0xd0e30db000000000000000000000000000000000000000000000000000000000)
                pop(
                    call(
                        gas(),
                        and(_wNative, ADDRESS_MASK),
                        amount, // ETH to deposit
                        ptr, // seletor for deposit()
                        0x4, // input size = selector
                        0x0, // output = empty
                        0x0 // output size = zero
                    )
                )
            }
            default {
                let ptr := mload(0x40) // free memory pointer

                // selector for borrow(uint256)
                mstore(ptr, 0xc5ebeaec00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x4), amount)

                let success := call(
                    gas(),
                    and(_cAsset, ADDRESS_MASK),
                    0x0,
                    ptr, // input = encoded data
                    0x24, // input size = selector + uint256
                    ptr, // output
                    0x0 // output size = zero
                )
                let rdsize := returndatasize()

                if iszero(success) {
                    returndatacopy(ptr, 0, rdsize)
                    revert(ptr, rdsize)
                }
            }
        }
    }
}
