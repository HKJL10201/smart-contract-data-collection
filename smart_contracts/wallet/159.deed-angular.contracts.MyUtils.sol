pragma solidity ^0.6.6;


library MyUtils {
    function readBytes4(bytes memory b, uint256 index)
        internal
        pure
        returns (bytes4 result)
    {
        index += 32;
        assembly {
            result := mload(add(b, index))
            result := and(
                result,
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
        return result;
    }

    function _toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function searchInsideArray(address search, address[] memory array)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == search) return true;
        }
        return false;
    }
}


interface CERC20 {
    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256)
        external
        returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address)
        external
        view
        returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function getCash() external returns (uint256);

    function balanceOfUnderlying(address) external view returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function repayBorrowBehalf(address, uint256) external returns (uint256);

    function borrowBalanceCurrent(address) external view returns (uint256);
}
