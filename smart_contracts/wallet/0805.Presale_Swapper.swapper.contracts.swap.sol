// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swap{
    address public owner; // deployer address
    address public tokenAddress; // erc20 token address
    IERC20 public token; //erc20 token defined address
    uint256 public ethOwner; // deployers ETH balance
    uint256 public ethUsers; // depositors ETH balance 
    uint public ethLimit; // limit of eth per depositer to send to contract
    uint public tokenLimit; // limit of tokens transfer to depositors
    mapping(address => bool) public privateList;

    constructor(address _tokenAddress, uint _ethlimit, uint _tokenlimit) payable {
        tokenAddress = _tokenAddress;
        token = IERC20(tokenAddress);
        owner = msg.sender;
        ethLimit = _ethlimit;
        tokenLimit = _tokenlimit;
    }

    event addtoPrivate(address);
    function addList(address _user) external byOwner {
        require(!privateList[_user]);
        privateList[_user] = true;
        emit addtoPrivate(_user);
    }

    function removeList(address _user) public {
        privateList[_user] = false;
    }

    function depositTokens(uint256 _amount) external payable byOwner {
        require(token.transferFrom(msg.sender, address(this), _amount));
    }

    function withdrawTokens(uint256 _amount) external byOwner {
        require(token.balanceOf(address(this)) >= _amount);
        token.transfer(msg.sender, _amount);
    }

    function tokenBalance() public view returns(uint) {
        uint balance = token.balanceOf(address(this));
        return balance;
    }

    function depositETH() external payable byOwner {
        uint256 value = msg.value;
        ethOwner += value;
    }

    function withdrawETH(uint _amount) external byOwner {
        payable(msg.sender).transfer(_amount);
    }

    modifier byOwner() {
        require(msg.sender == owner);
        _;
    }

    event swapTokens(address);
    receive() external payable {
        require(privateList[msg.sender]);
        require(msg.value >= ethLimit);
        token.transfer(msg.sender, tokenLimit);
        removeList(msg.sender);
        uint256 value = msg.value;
        ethUsers += value;
        emit swapTokens(msg.sender);
    }
}