//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ERC20Interface {

    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);

    function transfer(address _account, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);

    function approve(address _account, uint256 _amount) external returns (bool);
    function allowance(address _from, address _to) external view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approve(address indexed _from, address indexed _to, uint256 _amount);
}
