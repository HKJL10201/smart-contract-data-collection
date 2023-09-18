pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './libraries/Helpers.sol';

contract MultiSender is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  struct Payment {
    address _to;
    uint256 _amount;
  }

  uint256 FEE_PER_ADDRESSES;
  address FEE_ADDRESS;
  int256 FEE_BASIS;

  uint256 ACCUMULATED_FEE;

  address[] private _users;
  mapping(address => uint256) _usage;

  event Multisend(Payment[] _payments, address indexed _by, address _token, uint256 _fee, uint256 _totalAmount);

  constructor(
    address _feeAddress,
    uint256 _fee,
    int256 _feeBasis
  ) {
    FEE_ADDRESS = _feeAddress;
    FEE_PER_ADDRESSES = _fee;
    FEE_BASIS = _feeBasis;
  }

  function calcFee(uint256 length) public view returns (uint256) {
    return length.mul(FEE_PER_ADDRESSES).div(uint256(FEE_BASIS));
  }

  function setFeeAddress(address _feeAddress) external onlyOwner {
    require(FEE_ADDRESS != _feeAddress, 'ALREADY_SET');
    FEE_ADDRESS = _feeAddress;
  }

  function setFeeBasis(int256 _feeBasis) external onlyOwner {
    require(FEE_BASIS != _feeBasis, 'ALREADY_SET');
    FEE_BASIS = _feeBasis;
  }

  function setFeePerAddresses(uint256 _feePerAddresses) external onlyOwner {
    require(FEE_PER_ADDRESSES != _feePerAddresses, 'ALREADY_SET');
    FEE_PER_ADDRESSES = _feePerAddresses;
  }

  function _indexOfUsers(address _user) private view returns (uint256) {
    uint256 _index = uint256(int256(-1));

    for (uint256 i = 0; i < _users.length; i++) {
      if (_users[i] == _user) {
        _index = i;
      }
    }
    return _index;
  }

  function multisend(Payment[] memory _payments, address _token) external payable nonReentrant returns (bool) {
    uint256 _fee = calcFee(_payments.length);
    uint256 _totalAmount;

    if (_token == address(0)) {
      uint256 _totalPaymentAmount = 0;

      for (uint256 i = 0; i < _payments.length; i++)
        _totalPaymentAmount = _totalPaymentAmount.add(_payments[i]._amount);

      require(msg.value >= _totalPaymentAmount.add(_fee), 'MUST_INCLUDE_FEE or INSUFFICIENT_AMOUNT');

      for (uint256 i = 0; i < _payments.length; i++)
        require(Helpers._safeTransferETH(_payments[i]._to, _payments[i]._amount), 'COULD_NOT_TRANSFER_ETHER');

      _totalAmount = _totalPaymentAmount;
    } else {
      require(msg.value >= _fee, 'MUST_INCLUDE_FEE');

      uint256 _totalPaymentAmount = 0;

      for (uint256 i = 0; i < _payments.length; i++)
        _totalPaymentAmount = _totalPaymentAmount.add(_payments[i]._amount);

      require(IERC20(_token).allowance(_msgSender(), address(this)) >= _totalPaymentAmount, 'NO_ALLOWANCE');

      for (uint256 i = 0; i < _payments.length; i++)
        require(
          Helpers._safeTransferFrom(_token, _msgSender(), _payments[i]._to, _payments[i]._amount),
          'COULD_NOT_TRANSFER_TOKEN'
        );

      _totalAmount = _totalPaymentAmount;
    }

    if (_indexOfUsers(_msgSender()) == uint256(int256(-1))) {
      _users.push(_msgSender());
    }

    _usage[_msgSender()] = _usage[_msgSender()].add(1);
    ACCUMULATED_FEE = ACCUMULATED_FEE.add(_fee);

    emit Multisend(_payments, _msgSender(), _token, _fee, _totalAmount);
    return true;
  }

  function _resetUsage() private {
    for (uint256 i = 0; i < _users.length; i++) {
      _usage[_users[i]] = 0;
    }
  }

  function takeAccumulatedFees(int256 _percentage) external onlyOwner returns (bool) {
    require(_percentage > 0, 'PERCENTAGE_MUST_BE_GREATER_THAN_0');
    require(address(this).balance > 0, 'BALANCE_TOO_LOW');
    uint256 usage = 0;
    address _winner;

    for (uint256 i = 0; i < _users.length; i++) {
      if (_usage[_users[i]] > usage) {
        _winner = _users[i];
        usage = _usage[_users[i]];
      }
    }

    uint256 _amount = (uint256(_percentage) * ACCUMULATED_FEE).div(100);
    require(Helpers._safeTransferETH(FEE_ADDRESS, address(this).balance.sub(_amount)), 'COULD_NOT_TRANSFER_ETHER');
    require(Helpers._safeTransferETH(_winner, _amount), 'COULD_NOT_TRANSFER_ETHER');
    _resetUsage();
    ACCUMULATED_FEE = 0;
    return true;
  }
}
