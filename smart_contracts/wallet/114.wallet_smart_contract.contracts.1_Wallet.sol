//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract Wallet is Ownable, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //@Dev deployer of this contract will be the Owner and fee taker of this contract.

    //Here it is made temporarily 
    // public so it is readable when testing. in production, better stay private
    //and just make a getter function instead with view  onlyOwner
    // address private serviceProvider;
    
    //220305 05:56 fifth guy in ganache as fee taker, just to see if the fee send works.
    // address private serviceProvider = 0xCdf340E5B90fb5963d7637829E4751569eC8086f;

    //220308 16:15 for testing, I will just make the constructor assign address;
    address private serviceProvider;


    function whoBandit() view external onlyOwner returns(address) {
        return serviceProvider;
    }    

    //@Dev access control by Role added in order to make sure this wallet is used by the right
    //person
    //@Param user - address of this wallet contract needed
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    constructor(address user, address _comissionTaker) {
        // serviceProvider=msg.sender;
        _setupRole(USER_ROLE, user);
        serviceProvider = _comissionTaker;
    }

 
    //@Dev Owner of this contract and change fee
    //@Param newFee - fee in wei
    //Here it is made  temporarily 
    // public so it is readable when testing. in production, better stay private
    //and just make a getter function instead with view onlyOwner
    uint private fee = 999999999999999;

    function feeHow() view external onlyOwner returns(uint) {
        return fee;
    }

    event ChangedFee(uint indexed newFee);
    function changeFee(uint _new) external onlyOwner {
        fee = _new;
        emit ChangedFee(fee);
    }



    //@Dev to receiv ETH
    event Deposit(address indexed sender, uint indexed amount);

    fallback() external payable{
        emit Deposit(msg.sender, msg.value);
    }
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    //@Dev send ETH
    event WithdrawETH(address indexed receiver, uint indexed amount);
    //@Param _to - receiver of ETH
    // _valueInWei - how much to send)
    function sendETH(address _to, uint _valueInWei) external returns(bool) {
        require(hasRole(USER_ROLE, msg.sender), "Caller is not our user");
        require(address(this).balance >= _valueInWei, "balance ain't enough");
        (bool success1, ) = serviceProvider.call{value: fee}("");
        require(success1, "fee payment failed");
        uint rest = _valueInWei.sub(fee);
        (bool success2, ) = _to.call{value: rest}("");
        return success2;
        emit WithdrawETH(_to, rest);
    }


    // @Dev safeTransfer used for security issue.
    // @Param IERC20 _token - token that this wallet's user want to send.
    // _to - receiver's address   _amount - how much to send
    event WithdrawERC20(address indexed receiver, uint indexed amount);

    function sendToken(IERC20 _token, address _to, uint _amount) external {
        require(hasRole(USER_ROLE, msg.sender), "Caller is not our user");
        require(_token.balanceOf(address(this)) >= _amount, "Not enough tokens");
        _token.safeTransfer(_to, _amount);
        emit WithdrawERC20(_to, _amount);
    }
        

    // @Dev Please use this function for setting initial value of allowance, not for increasing
    // or decreasing the allowance value
    // @Param IERC20 _token - token that this wallet's user want to approve.
    // _spender - smart contract that will manipulate this contract's token
    // _amount - how much to allow

    event AllowanceInit(address indexed spender, uint indexed value);
    function approve(IERC20 _token, address _spender, uint _amount) external {
        require(hasRole(USER_ROLE, msg.sender), "Caller is not our user");
        require(_token.balanceOf(address(this)) >= _amount, "Not enough tokens");

        _token.safeApprove(_spender, _amount);
        emit AllowanceInit(_spender, _amount);
    }

    // @Dev Please use this function for increasing the allowance value
    // If you want to check current allowance of a token, please talk to the ERC20 token
    // that you are trying to increase allowance of 
    // @Param IERC20 _token - token that this wallet's user want to approve.
    // _spender - smart contract that will manipulate this contract's token
    // _amount - how much to allow


    event AllowanceIncBy(address indexed spender, uint indexed value);
    function allowanceIncreaseBy(IERC20 _token, address _spender, uint _amount) external {
        require(hasRole(USER_ROLE, msg.sender), "Caller is not our user");
        require(_token.balanceOf(address(this)) >= _amount, "Not enough tokens");
        _token.safeIncreaseAllowance(_spender, _amount);
        emit AllowanceIncBy(_spender, _amount);
    }

    // @Dev Please use this function for increasing the allowance value
    // If you want to check current allowance of a token, please talk to the ERC20 token
    // that you are trying to increase allowance of 
    // @Param IERC20 _token - token that this wallet's user want to approve.
    // _spender - smart contract that will manipulate this contract's token
    // _amount - how much to allow    

    event AllowanceDecBy(address indexed spender, uint indexed value);
    function allowanceDecreaseBy(IERC20 _token, address _spender, uint _amount) external {
        require(hasRole(USER_ROLE, msg.sender), "Caller is not our user");
        require(_token.balanceOf(address(this)) >= _amount, "Not enough tokens");
        _token.safeDecreaseAllowance(_spender, _amount);
        emit AllowanceDecBy(_spender, _amount);
    }

    function balance() view external returns(uint){
        return address(this).balance;
    }

}
