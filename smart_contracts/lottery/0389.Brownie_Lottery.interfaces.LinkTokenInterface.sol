pragma solidity ^0.6.6;

interrface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 );
    function approve(address spender, uint256 value) external returns (bool success);
    function balanceOf(address owner) external view returns (uint256 balance);
    function decimals() external view returns (decimalPlaces);
    function decreaseApproval(address spender, uint256 addedValue) external returns();
    function increaseApproval(address spender, uint256 subtractedValue) external;
    

}