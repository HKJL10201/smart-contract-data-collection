IR:

/// @use-src 0:"contracts/extras/call_2.sol"
object "Caller_33" {
    code {
        /// @src 0:64:342  "contract Caller {..."
        mstore(64, memoryguard(128))
        if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }

        constructor_Caller_33()

        let _1 := allocate_unbounded()
        codecopy(_1, dataoffset("Caller_33_deployed"), datasize("Caller_33_deployed"))

        return(_1, datasize("Caller_33_deployed"))

        function allocate_unbounded() -> memPtr {
            memPtr := mload(64)
        }

        function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() {
            revert(0, 0)
        }

        /// @src 0:64:342  "contract Caller {..."
        function constructor_Caller_33() {

            /// @src 0:64:342  "contract Caller {..."

        }
        /// @src 0:64:342  "contract Caller {..."

    }
    /// @use-src 0:"contracts/extras/call_2.sol"
    object "Caller_33_deployed" {
        code {
            /// @src 0:64:342  "contract Caller {..."
            mstore(64, memoryguard(128))

            if iszero(lt(calldatasize(), 4))
            {
                let selector := shift_right_224_unsigned(calldataload(0))
                switch selector

                case 0x166847df
                {
                    // arbitraryCall(address,uint256,bytes)

                    external_fun_arbitraryCall_32()
                }

                default {}
            }

            revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74()

            function shift_right_224_unsigned(value) -> newValue {
                newValue :=

                shr(224, value)

            }

            function allocate_unbounded() -> memPtr {
                memPtr := mload(64)
            }

            function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() {
                revert(0, 0)
            }

            function revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() {
                revert(0, 0)
            }

            function revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db() {
                revert(0, 0)
            }

            function cleanup_t_uint160(value) -> cleaned {
                cleaned := and(value, 0xffffffffffffffffffffffffffffffffffffffff)
            }

            function cleanup_t_address(value) -> cleaned {
                cleaned := cleanup_t_uint160(value)
            }

            function validator_revert_t_address(value) {
                if iszero(eq(value, cleanup_t_address(value))) { revert(0, 0) }
            }

            function abi_decode_t_address(offset, end) -> value {
                value := calldataload(offset)
                validator_revert_t_address(value)
            }

            function cleanup_t_uint256(value) -> cleaned {
                cleaned := value
            }

            function validator_revert_t_uint256(value) {
                if iszero(eq(value, cleanup_t_uint256(value))) { revert(0, 0) }
            }

            function abi_decode_t_uint256(offset, end) -> value {
                value := calldataload(offset)
                validator_revert_t_uint256(value)
            }

            function revert_error_1b9f4a0a5773e33b91aa01db23bf8c55fce1411167c872835e7fa00a4f17d46d() {
                revert(0, 0)
            }

            function revert_error_987264b3b1d58a9c7f8255e93e81c77d86d6299019c33110a076957a3e06e2ae() {
                revert(0, 0)
            }

            function round_up_to_mul_of_32(value) -> result {
                result := and(add(value, 31), not(31))
            }

            function panic_error_0x41() {
                mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
                mstore(4, 0x41)
                revert(0, 0x24)
            }

            function finalize_allocation(memPtr, size) {
                let newFreePtr := add(memPtr, round_up_to_mul_of_32(size))
                // protect against overflow
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr)) { panic_error_0x41() }
                mstore(64, newFreePtr)
            }

            function allocate_memory(size) -> memPtr {
                memPtr := allocate_unbounded()
                finalize_allocation(memPtr, size)
            }

            function array_allocation_size_t_bytes_memory_ptr(length) -> size {
                // Make sure we can allocate memory without overflow
                if gt(length, 0xffffffffffffffff) { panic_error_0x41() }

                size := round_up_to_mul_of_32(length)

                // add length slot
                size := add(size, 0x20)

            }

            function copy_calldata_to_memory_with_cleanup(src, dst, length) {
                calldatacopy(dst, src, length)
                mstore(add(dst, length), 0)
            }

            function abi_decode_available_length_t_bytes_memory_ptr(src, length, end) -> array {
                array := allocate_memory(array_allocation_size_t_bytes_memory_ptr(length))
                mstore(array, length)
                let dst := add(array, 0x20)
                if gt(add(src, length), end) { revert_error_987264b3b1d58a9c7f8255e93e81c77d86d6299019c33110a076957a3e06e2ae() }
                copy_calldata_to_memory_with_cleanup(src, dst, length)
            }

            // bytes
            function abi_decode_t_bytes_memory_ptr(offset, end) -> array {
                if iszero(slt(add(offset, 0x1f), end)) { revert_error_1b9f4a0a5773e33b91aa01db23bf8c55fce1411167c872835e7fa00a4f17d46d() }
                let length := calldataload(offset)
                array := abi_decode_available_length_t_bytes_memory_ptr(add(offset, 0x20), length, end)
            }

            function abi_decode_tuple_t_addresst_uint256t_bytes_memory_ptr(headStart, dataEnd) -> value0, value1, value2 {
                if slt(sub(dataEnd, headStart), 96) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

                {

                    let offset := 0

                    value0 := abi_decode_t_address(add(headStart, offset), dataEnd)
                }

                {

                    let offset := 32

                    value1 := abi_decode_t_uint256(add(headStart, offset), dataEnd)
                }

                {

                    let offset := calldataload(add(headStart, 64))
                    if gt(offset, 0xffffffffffffffff) { revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db() }

                    value2 := abi_decode_t_bytes_memory_ptr(add(headStart, offset), dataEnd)
                }

            }

            function abi_encode_tuple__to__fromStack(headStart ) -> tail {
                tail := add(headStart, 0)

            }

            function external_fun_arbitraryCall_32() {

                if callvalue() { revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb() }
                let param_0, param_1, param_2 :=  abi_decode_tuple_t_addresst_uint256t_bytes_memory_ptr(4, calldatasize())
                fun_arbitraryCall_32(param_0, param_1, param_2)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple__to__fromStack(memPos  )
                return(memPos, sub(memEnd, memPos))

            }

            function revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74() {
                revert(0, 0)
            }

            function allocate_memory_array_t_bytes_memory_ptr(length) -> memPtr {
                let allocSize := array_allocation_size_t_bytes_memory_ptr(length)
                memPtr := allocate_memory(allocSize)

                mstore(memPtr, length)

            }

            function zero_value_for_split_t_bytes_memory_ptr() -> ret {
                ret := 96
            }

            function extract_returndata() -> data {

                switch returndatasize()
                case 0 {
                    data := zero_value_for_split_t_bytes_memory_ptr()
                }
                default {
                    data := allocate_memory_array_t_bytes_memory_ptr(returndatasize())
                    returndatacopy(add(data, 0x20), 0, returndatasize())
                }

            }

            function cleanup_t_bool(value) -> cleaned {
                cleaned := iszero(iszero(value))
            }

            function array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, length) -> updated_pos {
                mstore(pos, length)
                updated_pos := add(pos, 0x20)
            }

            function store_literal_in_memory_df4b36f462e8845f11209535bb098e39912100cc7f82e9bb1c249c245b02f1fd(memPtr) {

                mstore(add(memPtr, 0), "Call Failed")

            }

            function abi_encode_t_stringliteral_df4b36f462e8845f11209535bb098e39912100cc7f82e9bb1c249c245b02f1fd_to_t_string_memory_ptr_fromStack(pos) -> end {
                pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 11)
                store_literal_in_memory_df4b36f462e8845f11209535bb098e39912100cc7f82e9bb1c249c245b02f1fd(pos)
                end := add(pos, 32)
            }

            function abi_encode_tuple_t_stringliteral_df4b36f462e8845f11209535bb098e39912100cc7f82e9bb1c249c245b02f1fd__to_t_string_memory_ptr__fromStack(headStart ) -> tail {
                tail := add(headStart, 32)

                mstore(add(headStart, 0), sub(tail, headStart))
                tail := abi_encode_t_stringliteral_df4b36f462e8845f11209535bb098e39912100cc7f82e9bb1c249c245b02f1fd_to_t_string_memory_ptr_fromStack( tail)

            }

            /// @ast-id 32
            /// @src 0:125:340  "function arbitraryCall(address recipient, uint value, bytes memory data) public {..."
            function fun_arbitraryCall_32(var_recipient_7, var_value_9, var_data_11_mpos) {

                /// @src 0:230:239  "recipient"
                let _1 := var_recipient_7
                let expr_16 := _1
                /// @src 0:230:244  "recipient.call"
                let expr_17_address := expr_16
                /// @src 0:252:257  "value"
                let _2 := var_value_9
                let expr_18 := _2
                /// @src 0:230:258  "recipient.call{value: value}"
                let expr_19_address := expr_17_address
                let expr_19_value := expr_18
                /// @src 0:259:263  "data"
                let _3_mpos := var_data_11_mpos
                let expr_20_mpos := _3_mpos
                /// @src 0:230:264  "recipient.call{value: value}(data)"

                let _4 := add(expr_20_mpos, 0x20)
                let _5 := mload(expr_20_mpos)

                let expr_21_component_1 := call(gas(), expr_19_address,  expr_19_value,  _4, _5, 0, 0)
                let expr_21_component_2_mpos := extract_returndata()
                /// @src 0:211:264  "(bool success, ) = recipient.call{value: value}(data)"
                let var_success_15 := expr_21_component_1
                /// @src 0:275:282  "success"
                let _6 := var_success_15
                let expr_23 := _6
                /// @src 0:274:282  "!success"
                let expr_24 := cleanup_t_bool(iszero(expr_23))
                /// @src 0:270:333  "if (!success) {..."
                if expr_24 {
                    /// @src 0:301:326  "CallFailed(\"Call Failed\")"
                    {
                        let _7 := allocate_unbounded()
                        mstore(_7, 82267685780540246715539941338396408876926397280071070808468003743377366450176)
                        let _8 := abi_encode_tuple_t_stringliteral_df4b36f462e8845f11209535bb098e39912100cc7f82e9bb1c249c245b02f1fd__to_t_string_memory_ptr__fromStack(add(_7, 4) )
                        revert(_7, sub(_8, _7))
                    }/// @src 0:270:333  "if (!success) {..."
                }

            }
            /// @src 0:64:342  "contract Caller {..."

        }

        data ".metadata" hex"a2646970667358221220b09cab4fc3b77de71bd832dfd30f6f6cb41fde780f934444bfbc1fe9f82a524064736f6c63430008120033"
    }

}


