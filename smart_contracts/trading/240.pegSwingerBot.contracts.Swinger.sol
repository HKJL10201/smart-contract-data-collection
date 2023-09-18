//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Adapter.sol";
import "./Sweepable.sol";

contract Swinger is Ownable, Sweepable {
    IERC20 public immutable mainAsset;
    IERC20 public immutable peggedAsset;
    Adapter public adapter;
    address public keeper;
    address public treasury;
    uint public lowerBound = 1086;
    uint public upperbound = 970;

    constructor(address _mainAsset, address _peggedAsset, address _adapter) {
        mainAsset = IERC20(_mainAsset);
        peggedAsset = IERC20(_peggedAsset);
        adapter = Adapter(_adapter);
        keeper = msg.sender;
        treasury = msg.sender;
    }

    modifier onlyKeeper() {
        require(keeper == _msgSender(), "caller is not the keeper");
        _;
    }

    function swing(bool toPegged) public onlyKeeper {
        IERC20 from = toPegged ? mainAsset : peggedAsset;
        IERC20 to = toPegged ? peggedAsset : mainAsset;
        uint balance = from.balanceOf(treasury);
        uint ratio = toPegged ? lowerBound : upperbound;
        uint amountOutMin = balance / 1000 * ratio;
        uint toBalance = to.balanceOf(treasury);

        // transfer fro  treasury to the adapter
        bool result = from.transferFrom(treasury, address(adapter), balance);
        require(result, "transfer failed");

        adapter.swap(from, to, balance, amountOutMin, treasury);

        uint newToBalance = to.balanceOf(address(treasury));
        require((newToBalance - toBalance) > amountOutMin, "too high slippage");

        if (toPegged) {
            require(balance < newToBalance, "unexpected lower balance for pegged asset");
        }
    }

    function getRatio(uint amount, bool toPegged) public view returns (uint) {
        IERC20 from = toPegged ? mainAsset : peggedAsset;
        IERC20 to = toPegged ? peggedAsset : mainAsset;
        uint balance = amount == 0 ? from.balanceOf(treasury) : amount;

        return adapter.getRatio(from, to, balance);
    }

    function setLimits(uint _lowerBound, uint _upperBound) public onlyOwner {
        lowerBound = _lowerBound;
        upperbound = _upperBound;
    }

    function setKeeper(address _keeper) public onlyOwner {
        keeper = _keeper;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }
}
