// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract QuickSort {
    function sort(uint256[] memory data) public pure returns (uint256[] memory) {
        quickSort(data, int256(0), int256(data.length - 1));
        return data;
    }

    function reverseSort(uint256[] memory data) public pure returns (uint256[] memory) {
        quickSortReverse(data, int256(0), int256(data.length - 1));
        return data;
    }

    //Returns the sorted indexes
    function sortWithIndex(uint256[] memory data, uint256[] memory indices) public pure returns (uint256[] memory) {
        quickSortWithIndex(data, indices, int256(0), int256(data.length - 1));
        return indices;
    }

    function reverseSortWithIndex(uint256[] memory data, uint256[] memory indices)
        public
        pure
        returns (uint256[] memory)
    {
        quickReverseSortWithIndex(data, indices, int256(0), int256(data.length - 1));
        return indices;
    }

    function quickSort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;

        if (i == j) return;

        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) {
                i++;
            }

            while (pivot < arr[uint256(j)]) {
                j--;
            }

            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }

        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function quickSortReverse(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;

        if (i == j) return;

        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] > pivot) {
                i++;
            }

            while (pivot > arr[uint256(j)]) {
                j--;
            }

            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }

        if (left < j) quickSortReverse(arr, left, j);
        if (i < right) quickSortReverse(arr, i, right);
    }

    function quickSortWithIndex(
        uint256[] memory arr,
        uint256[] memory indices,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;

        if (i == j) return;

        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                (indices[uint256(i)], indices[uint256(j)]) = (indices[uint256(j)], indices[uint256(i)]);
                i++;
                j--;
            }
        }

        if (left < j) quickSortWithIndex(arr, indices, left, j);
        if (i < right) quickSortWithIndex(arr, indices, i, right);
    }

    function quickReverseSortWithIndex(
        uint256[] memory arr,
        uint256[] memory indices,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;

        if (i == j) return;

        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] > pivot) {
                i++;
            }

            while (pivot > arr[uint256(j)]) {
                j--;
            }

            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                (indices[uint256(i)], indices[uint256(j)]) = (indices[uint256(j)], indices[uint256(i)]);
                i++;
                j--;
            }
        }

        if (left < j) quickReverseSortWithIndex(arr, indices, left, j);
        if (i < right) quickReverseSortWithIndex(arr, indices, i, right);
    }
}
