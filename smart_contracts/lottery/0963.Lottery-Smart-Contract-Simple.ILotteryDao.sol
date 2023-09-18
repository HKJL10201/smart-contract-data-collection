pragma solidity ^0.5.0;

interface ILotteryDao {
    enum Era {
        EXPANSION,
        NEUTRAL,
        DEBT
    }

    function treasury() external view returns (address);
    function dollar() external view returns (address);
    function era() external view returns (Era, uint256);
    function epoch() external view returns (uint256);

    function requestDAI(address recipient, uint256 amount) external;
}