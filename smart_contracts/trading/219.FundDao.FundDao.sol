// SPDX-License-Identifier: MIT
// Author: tristanh00
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FundDao is ReentrancyGuard {
    address payable public dev;
    address payable public owner;
    address payable public fund;
    address[] public depositorsList;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool public withdrawalAllowed = false;

    uint256 public totalDeposited = 0;
    uint256 public totalProfits = 0;
    uint256 public devFee = 1;
    uint256 public fundFee = 19;
    uint256 public ownerFee = 30;
    uint256 public shareholderFee = 50;

    IUniswapV2Router02 public constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER);

    struct Depositor {
        uint256 deposit;
        uint256 payout;
        bool active;
    }

    mapping(address => Depositor) public depositors;

    constructor(address payable _dev, address payable _fund, address payable _owner) {
        dev = _dev;
        fund = _fund;
        owner = _owner;
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not dev");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == dev, "Caller is not admin");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function updateDev(address payable _dev) external onlyDev {
        require(_dev != address(0), "Dev cannot be zero address");
        dev = _dev;
    }

    function updateFund(address payable _fund) external onlyOwner {
        require(_fund != address(0), "Fund cannot be zero address");
        fund = _fund;
    }

    function updateOwner(address payable _owner) external onlyOwner {
        require(_owner != address(0), "Owner cannot be zero address");
        owner = _owner;
    }

    function updateFees(uint256 _devFee, uint256 _fundFee, uint256 _ownerFee, uint256 _shareholderFee) external onlyAdmin {
        require(_devFee + _fundFee + _ownerFee + _shareholderFee == 100, "Fee percentages must add up to 100%");
        devFee = _devFee;
        fundFee = _fundFee;
        ownerFee = _ownerFee;
        shareholderFee = _shareholderFee;
    }

    function updateWithdrawal(bool _allow) external onlyOwner {
        withdrawalAllowed = _allow;
    }

    function transferTokens(address _token, address _recipient, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(_token != address(0), "Token cannot be zero address");
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Not enough tokens in contract");

        IERC20(_token).transfer(_recipient, _amount);
    }

    function transferEth(address payable _recipient, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(address(this).balance >= _amount, "Not enough ETH in contract");

        _recipient.transfer(_amount);
    }

    function swap(uint256 _amountIn, uint256 _amountOutMin, address _tokenIn, address _tokenOut, uint256 _deadline) external onlyOwner {
        require(_amountIn > 0, "amountIn must be greater than 0");
        require(_amountOutMin > 0, "amountOutMin must be greater than 0");
        require(_deadline > 0, "deadline must be greater than 0");
        require(_tokenIn != address(0), "tokenIn address cannot be zero address");
        require(_tokenOut != address(0), "tokenOut address cannot be zero address");
        require(IERC20(_tokenIn).balanceOf(address(this)) >= _amountIn, "Insufficient tokenIn balance");
        
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        // Perform the swap
        address[] memory _path = new address[](2);
        _path[0] = _tokenIn;
        _path[1] = _tokenOut;
        
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _amountOutMin,
            _path,
            address(this),
            _deadline
        );
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Deposit must be greater than 0");
        require(IERC20(WETH).balanceOf(msg.sender) >= _amount, "Insufficient balance");

        IERC20(WETH).transferFrom(msg.sender, address(this), _amount);

        totalDeposited += _amount;

        if (!depositors[msg.sender].active) {
            depositorsList.push(msg.sender);
            depositors[msg.sender].active = true;
        }

        depositors[msg.sender].deposit += _amount;
    }

    function withdraw(bool _withdrawAll) external nonReentrant {
        require(withdrawalAllowed, "Withdrawals are currently not allowed");

        Depositor storage _depositor = depositors[msg.sender];

        uint256 _payout = _depositor.payout;
        require(_payout > 0, "No profits to withdraw");
        require(_payout <= IERC20(WETH).balanceOf(address(this)), "Profit withdrawal exceeds contract balance");
        require(_payout <= totalProfits, "Profit withdrawal exceeds available profits");

        totalProfits -= _payout;
        _depositor.payout = 0;
        
        if (_withdrawAll) {
            uint256 _deposit = _depositor.deposit;
            require(_deposit > 0, "You have no funds to withdraw");
            require(_deposit + _payout <= IERC20(WETH).balanceOf(address(this)), "Withdrawal amount exceeds contract balance");

            totalDeposited -= _depositor.deposit;

            _depositor.deposit = 0;
            _depositor.active = false;

            IERC20(WETH).transfer(msg.sender, _deposit + _payout);
        } else {
            IERC20(WETH).transfer(msg.sender, _payout);
        }
    }

    function distributeProfits(uint256 _totalProfits) external onlyAdmin {
        require(IERC20(WETH).balanceOf(address(this)) >= _totalProfits, "Not enough WETH in contract");

        uint256 _shareholderFee = _totalProfits * shareholderFee / 100; 
        uint256 _devFee = _totalProfits * devFee / 100;
        uint256 _fundFee = _totalProfits * fundFee / 100;
        uint256 _ownerFee = _totalProfits * ownerFee / 100;

        for (uint i = 0; i < depositorsList.length; i++) {

            address _shareholder = depositorsList[i];
            Depositor storage _depositor = depositors[_shareholder];

            if (_depositor.active && _depositor.payout < 1) {
                uint256 _profits = (_shareholderFee * _depositor.deposit) / totalDeposited;
                _depositor.payout = _profits;
            }

        }

        require(IERC20(WETH).transfer(dev, _devFee), "Failed to transfer fee to dev wallet");
        require(IERC20(WETH).transfer(fund, _fundFee), "Failed to transfer fee to fund wallet");
        require(IERC20(WETH).transfer(owner, _ownerFee), "Failed to transfer fee to owner wallet");

        totalProfits = _totalProfits - (_devFee + _fundFee + _ownerFee); // Adjust totalProfits
    }

    receive() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        totalDeposited += msg.value;

        if (!depositors[msg.sender].active) {
            depositorsList.push(msg.sender);
            depositors[msg.sender].active = true;
        }

        depositors[msg.sender].deposit += msg.value;
    }
}
