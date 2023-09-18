// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        address[] _collection;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(
        Set storage set,
        bytes32 value,
        address addressValue
    ) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            address lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
            //            for(uint256 i = 0; i < set._collection.length; i++) {
            //                if (set._collection[i] == addressValue) {
            //                    _removeIndexArray(i, set._collection);
            //                    break;
            //                }
            //            }
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _collection(Set storage set)
        private
        view
        returns (address[] memory)
    {
        return set._collection;
    }

    //    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
    //        for(uint256 i = index; i < array.length-1; i++) {
    //            array[i] = array[i+1];
    //        }
    //        array.pop();
    //    }
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))), value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function collection(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        return _collection(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }
}
