pragma solidity ^0.6.6;


interface aToken {
    function redirectInterestStream(address) external;

    function redirectInterestStreamOf(address, address) external;

    function allowInterestRedirectionTo(address) external;

    function redeem(uint256) external;

    function principalBalanceOf(address) external view returns (uint256);

    function isTransferAllowed(address, uint256) external view returns (bool);

    function getInterestRedirectionAddress(address)
        external
        view
        returns (address);

    function getRedirectedBalance(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}


interface ILendingPoolCore {
    function getReserveATokenAddress(address) external view returns (address);
}
