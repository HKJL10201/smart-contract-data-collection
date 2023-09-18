// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// I1InchRouter is an interface for the 1Inch Router.
interface I1InchRouter {
    event Swapped(
        address indexed sender,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 destAmount
    );

     function Swap(
        address srcToken,
        address destToken,
        uint256 srcAmount,
        uint256 destAmount,
        address[] calldata path,
        address beneficiary,
        uint256 deadline
     ) external payable;

 
    function getExpectedReturn(
        IERC20 srcToken,
        IERC20 destToken,
        uint256 srcAmount
    ) external view returns (uint256);

        function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

And here the function from the simple swap contract calling I1inchRouter,sol:

function performSingleSwap(
    address _participant,
    address _inputToken,
    address _outputToken,
    uint256 _value,
    bytes32 _secretHash,
    uint256 _timelock
) external nonReentrant {
    uint256 requiredAmount = getRequiredAmount(_value);
    atomicSwapInstance.initiateSwap(
        _participant,
        _inputToken,
        requiredAmount,
        _secretHash,
        _timelock
    );

    address[] memory path = new address[](2);
    path[0] = _inputToken;
    path[1] = _outputToken;

    uint256 deadline = block.timestamp + 300; // 5 minutes from now

    IERC20(_inputToken).approve(address(oneInchRouter), requiredAmount);

    uint256 minReturn = oneInchRouter.getAmountsOut(requiredAmount, path)[1];

    oneInchRouter.swap(
        _inputToken,
        _outputToken,
        requiredAmount,
        minReturn,
        path,
        msg.sender, // Beneficiary receiving the swapped tokens
        deadline
    );
}
