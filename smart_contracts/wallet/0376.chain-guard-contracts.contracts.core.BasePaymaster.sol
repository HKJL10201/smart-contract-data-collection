pragma solidity ^0.8.12;

import "../interfaces/IPaymaster.sol";
import "../interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BasePaymaster is IPaymaster, Ownable {
  IEntryPoint public immutable entryPoint;

  constructor(IEntryPoint _entryPoint) {
    entryPoint = _entryPoint;
  }

  function _requireFromEntryPoint() internal virtual {
    require(msg.sender == address(entryPoint), "Sender not EntryPoint");
  }

  function _validatePaymasterUserOp(
    UserOperation calldata userOp,
    bytes32 userOpHash,
    uint256 maxCost
  ) internal virtual returns (bytes memory context, uint256 validationData);

  function _postOp(
    PostOpMode mode,
    bytes calldata context,
    uint256 actualGasCost
  ) internal virtual {
    (mode, context, actualGasCost);

    revert("must override");
  }

  ///@inheritdoc IPaymaster
  function postOp(
    PostOpMode mode,
    bytes calldata context,
    uint256 actualGasCost
  ) external override {
    _requireFromEntryPoint();
    _postOp(mode, context, actualGasCost);
  }

  function validatePaymasterUserOp(
    UserOperation calldata userOp,
    bytes32 userOpHash,
    uint256 maxCost
  ) external override returns (bytes memory context, uint256 validationData) {
    _requireFromEntryPoint();
    return _validatePaymasterUserOp(userOp, userOpHash, maxCost);
  }

  function deposit() public payable {
    entryPoint.depositTo{ value: msg.value }(address(this));
  }

  function withdrawTo(
    address payable withdrawAddress,
    uint256 amount
  ) public onlyOwner {
    entryPoint.withdrawTo(withdrawAddress, amount);
  }

  function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
    entryPoint.addStake{ value: msg.value }(unstakeDelaySec);
  }

  function getDeposit() public view returns (uint256) {
    return entryPoint.balanceOf(address(this));
  }

  function unlockStake() external onlyOwner {
    entryPoint.unlockStake();
  }

  function withdrawStake(address payable withdrawAddress) external onlyOwner {
    entryPoint.withdrawStake(withdrawAddress);
  }
}
