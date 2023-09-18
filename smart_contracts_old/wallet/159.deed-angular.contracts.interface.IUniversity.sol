pragma solidity ^0.6.6;


interface IUniversity {
    function name() external view returns (bytes32);

    function universityFund() external view returns (address);

    function availableFunds() external view returns (uint256);

    function availableFundsForInvestment() external view returns (uint256);

    function cut() external view returns (uint24);

    function isValidClassroom(address) external view returns (bool);

    function studentRequestClassroom(
        address,
        bytes32,
        uint24,
        uint24,
        int32,
        uint256,
        uint256,
        address
    ) external returns (address);

    function viewMyApplications() external view returns (address[] memory);

    function viewStudentApplications(address)
        external
        view
        returns (address[] memory);

    function studentIsRegistered(address) external view returns (bool);

    function registerStudentApplication(address, address) external;

    function addStudentScore(address, int32) external;

    function subStudentScore(address, int32) external;

    function giveGrant(address, uint256) external;

    function donateDAI(uint256) external;

    function reinvestReturns(uint256) external;

    function accountRevenue(uint256) external;

    function spendBudget(address, uint256) external;

    function applyFunds(uint256) external;

    function recoverFunds(uint256) external;

    function applyFundsETH(uint256) external;

    function recoverFundsETH(uint256) external;

}
