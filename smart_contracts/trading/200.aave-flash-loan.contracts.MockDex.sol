// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

error MockDex__NotOwner();

contract MockDex {
    address private immutable i_owner;

    // Aave ERC20 Token addresses on Goerli network
    // daiAddress = 0xDF1742fE5b0bFc12331D8EAec6b478DfDbD31464;
    // usdcAddress = 0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43;

    IERC20 private dai;
    IERC20 private usdc;

    // exchange rate indexes
    uint256 dexARate = 90;
    uint256 dexBRate = 100;

    // keeps track of individuals' dai balances
    mapping(address => uint256) public daiBalances;

    // keeps track of individuals' USDC balances
    mapping(address => uint256) public usdcBalances;

    modifier onlyOwner() {
        if (msg.sender != i_owner) { revert MockDex__NotOwner(); }
        _;
    }

    constructor(address _daiAddress, address _usdcAddress) {
        i_owner = msg.sender;
        dai = IERC20(_daiAddress);
        usdc = IERC20(_usdcAddress);
    }

    function depositUSDC(uint256 _amount) external {
        usdcBalances[msg.sender] += _amount;
        uint256 allowance = usdc.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        usdc.transferFrom(msg.sender, address(this), _amount);
    }

    function depositDAI(uint256 _amount) external {
        daiBalances[msg.sender] += _amount;
        uint256 allowance = dai.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        dai.transferFrom(msg.sender, address(this), _amount);
    }

    function buyDAI() external {
        uint256 daiToReceive = ((usdcBalances[msg.sender] / dexARate) * 100) *
            (10**12);
        dai.transfer(msg.sender, daiToReceive);
    }

    function sellDAI() external {
        uint256 usdcToReceive = ((daiBalances[msg.sender] * dexBRate) / 100) /
            (10**12);
        usdc.transfer(msg.sender, usdcToReceive);
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    receive() external payable {}
}