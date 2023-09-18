// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Collection of functions related to array 256 types.
 *
 * Originally based on code by Zabo. It has been upgraded to be compatible with
 * solidity version ^0.6 and apply `SafeMath` library for security improvement.
 *
 * For more details, please check their GitHub link https://github.com/modular-network/ethereum-libraries
 */
library Arrays256 {
    using SafeMath for uint256;

    /**
     * @dev Sorts given array in place
     */
    function heapSort(uint256[] storage array) internal {
        uint256 end = array.length - 1;
        uint256 start = _getParentI(end);
        uint256 root = start;
        uint256 lChild;
        uint256 rChild;
        uint256 swap;
        uint256 temp;

        while (start >= 0) {
            root = start;
            lChild = _getLeftChildI(start);

            while (lChild <= end) {
                rChild = lChild.add(1);
                swap = root;

                if (array[swap] < array[lChild]) {
                    swap = lChild;
                }

                if ((rChild <= end) && (array[swap] < array[rChild])) {
                    swap = rChild;
                }

                if (swap == root) {
                    lChild = end.add(1);
                } else {
                    temp = array[swap];
                    array[swap] = array[root];
                    array[root] = temp;
                    root = swap;
                    lChild = _getLeftChildI(root);
                }
            }

            if (start == 0) {
                break;
            } else {
                start = start.sub(1);
            }
        }

        while (end > 0) {
            temp = array[end];
            array[end] = array[0];
            array[0] = temp;
            end = end.sub(1);
            root = 0;
            lChild = _getLeftChildI(0);

            while (lChild <= end) {
                rChild = lChild.add(1);
                swap = root;

                if (array[swap] < array[lChild]) {
                    swap = lChild;
                }

                if ((rChild <= end) && (array[swap] < array[rChild])) {
                    swap = rChild;
                }

                if (swap == root) {
                    lChild = end.add(1);
                } else {
                    temp = array[swap];
                    array[swap] = array[root];
                    array[root] = temp;
                    root = swap;
                    lChild = _getLeftChildI(root);
                }
            }
        }
    }

    /**
     * @dev Utility function for heapSort
     */
    function _getParentI(uint256 index) private pure returns (uint256) {
        uint256 i = index.sub(1);
        return i.div(2);
    }

    /**
     * @dev Utility function for heapSort
     */
    function _getLeftChildI(uint256 index) private pure returns (uint256) {
        uint256 i = index.mul(2);
        return i.add(1);
    }
}
