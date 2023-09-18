// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./EIP712MetaTransaction.sol";

contract TimeLock is EIP712MetaTransaction, ReentrancyGuard, Ownable {
    uint256 public timelockPeriod;

    struct depositDetails {
        uint256 amount;
        uint256 timelocked;
    }

    struct withdrawVoucher {
        address user;
        address token;
        uint256 amount;
        bytes signature;
    }

    mapping(address => bool) public supportedTokens;

    // User -> Token -> {Amount, Timelock}
    mapping(address => mapping(address => depositDetails)) public depositData;

    event depositStatus(address token, uint256 amount, uint256 timelocked);

    event withdrawStatus(address token, uint256 amount);

    modifier checkSupportedTokens(address _token) {
        require(
            supportedTokens[_token],
            "Timelock: Token Address currently not supported"
        );
        _;
    }

    constructor(
        uint256 _timelockPeriod,
        address _tokenAddress
    ) EIP712MetaTransaction("TimeLock","V1") {
        require(
            IERC20(_tokenAddress).totalSupply() > 0,
            "Not a valid ERC20 address"
        );
        require(
            _timelockPeriod > 10,
            "Timelock should be greater than 10 seconds"
        );
        timelockPeriod = _timelockPeriod;
        supportedTokens[_tokenAddress] = true;
    }

    /* 
    *****************************
            FUNCTIONALITY                
    *****************************
    */
    function depositERC20(address _token, uint256 _amount)
        public
        checkSupportedTokens(_token)
    {
        require(
            IERC20(_token).balanceOf(_msgSender()) >= _amount,
            "TimeLock -> ERC20: User balance insufficient"
        );
        require(
            IERC20(_token).allowance(_msgSender(), address(this)) >= _amount,
            "TimeLock -> ERC20: Allowance insufficient"
        );

        IERC20(_token).transferFrom(_msgSender(), address(this), _amount);
        depositDetails storage currentDeposit = depositData[_msgSender()][
            _token
        ];
        depositData[_msgSender()][_token] = depositDetails(
            currentDeposit.amount + _amount,
            block.timestamp + timelockPeriod
        );
        emit depositStatus(
            _token,
            depositData[_msgSender()][_token].amount,
            depositData[_msgSender()][_token].timelocked
        );
    }

    function depositEther() public payable {
        depositDetails storage currentDeposit = depositData[_msgSender()][
            address(0)
        ];
        depositData[_msgSender()][address(0)] = depositDetails(
            currentDeposit.amount + msg.value,
            block.timestamp + timelockPeriod
        );
        emit depositStatus(
            address(0),
            depositData[_msgSender()][address(0)].amount,
            depositData[_msgSender()][address(0)].timelocked
        );
    }

    fallback() external payable {
        depositEther();
    }

    receive() external payable {
        depositEther();
    }

    function withdrawERC20Direct(address _token, uint256 _amount)
        public
        checkSupportedTokens(_token)
    {
        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "TimeLock -> ERC20: Contract balance insufficient"
        );

        depositDetails storage currentDeposit = depositData[_msgSender()][
            _token
        ];
        require(
            currentDeposit.amount >= _amount,
            "TimeLock: Withdraw request greater than deposit amount"
        );
        require(
            currentDeposit.timelocked < block.timestamp,
            "TimeLock: Tokens currently under timelock period"
        );

        depositData[_msgSender()][_token] = depositDetails(
            currentDeposit.amount - _amount,
            block.timestamp - 1
        );

        IERC20(_token).transfer(_msgSender(), _amount);
        emit withdrawStatus(
            _token,
            depositData[_msgSender()][address(0)].amount
        );
    }

    function withdrawEtherDirect(uint256 _amount) public {
        require(
            address(this).balance >= _amount,
            "TimeLock: Contract balance insufficient"
        );

        depositDetails storage currentDeposit = depositData[_msgSender()][
            address(0)
        ];
        require(
            currentDeposit.amount >= _amount,
            "TimeLock: Withdraw request greater than deposit amount"
        );
        require(
            currentDeposit.timelocked < block.timestamp,
            "TimeLock: Ether currently under timelock period"
        );

        depositData[_msgSender()][address(0)] = depositDetails(
            currentDeposit.amount - _amount,
            block.timestamp - 1
        );
        (bool sent, bytes memory data) = _msgSender().call{value: _amount}("");
        require(sent, "TimeLock: Ether transfer failed");
        emit withdrawStatus(
            address(0),
            depositData[_msgSender()][address(0)].amount
        );
    }

    function withdrawWithVoucher(withdrawVoucher calldata _voucher) public {
        require(verify(_voucher), "Timelock: Voucher not signed by user");
        if (_voucher.token == address(0)) {
            require(
            address(this).balance >= _voucher.amount,
            "TimeLock: Contract balance insufficient"
        );

        depositDetails storage currentDeposit = depositData[_voucher.user][
            address(0)
        ];
        require(
            currentDeposit.amount >= _voucher.amount,
            "TimeLock: Withdraw request greater than deposit amount"
        );
        require(
            currentDeposit.timelocked < block.timestamp,
            "TimeLock: Ether currently under timelock period"
        );

        depositData[_voucher.user][address(0)] = depositDetails(
            currentDeposit.amount - _voucher.amount,
            block.timestamp - 1
        );
        (bool sent, bytes memory data) = _voucher.user.call{value: _voucher.amount}("");
        require(sent, "TimeLock: Ether transfer failed");
        emit withdrawStatus(
            address(0),
            depositData[_voucher.user][address(0)].amount
        );
        } else {
            require(
            IERC20(_voucher.token).balanceOf(address(this)) >= _voucher.amount,
            "TimeLock -> ERC20: Contract balance insufficient"
        );

        depositDetails storage currentDeposit = depositData[_voucher.user][
            _voucher.token
        ];
        require(
            currentDeposit.amount >= _voucher.amount,
            "TimeLock: Withdraw request greater than deposit amount"
        );
        require(
            currentDeposit.timelocked < block.timestamp,
            "TimeLock: Tokens currently under timelock period"
        );

        depositData[_voucher.user][_voucher.token] = depositDetails(
            currentDeposit.amount - _voucher.amount,
            block.timestamp - 1
        );

        IERC20(_voucher.token).transfer(_voucher.user, _voucher.amount);
        emit withdrawStatus(
            _voucher.token,
            depositData[_voucher.user][address(0)].amount
        );
        }
    }

    /* 
    ***********************
            GETTERS        
    ***********************
    */

    function getEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getVoucherHash(withdrawVoucher calldata _voucher)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(_voucher.user, _voucher.token, _voucher.amount)
            );
    }

    /* 
    ****************************
            OWNERS ONLY         
    ****************************
    */

    function editTimelockPeriod(uint256 _timelockPeriod) public onlyOwner {
        timelockPeriod = _timelockPeriod;
    }

    function addNewToken(address _tokenAddress) public onlyOwner {
        require(
            IERC20(_tokenAddress).totalSupply() > 0,
            "TimeLock: Not a valid ERC20 address"
        );
        require(
            !supportedTokens[_tokenAddress],
            "TimeLock: Token already supported"
        );
        supportedTokens[_tokenAddress] = true;
    }

    function removeTokenSupport(address _tokenAddress) public onlyOwner {
        require(
            supportedTokens[_tokenAddress],
            "TimeLock: Token was not supported"
        );
        supportedTokens[_tokenAddress] = false;
    }

    /* 
    ********************************
            UTILS & INTERNALS       
    ********************************
    */

    function verify(withdrawVoucher calldata _voucher)
        public
        pure
        returns (bool)
    {
        bytes32 messageHash = getVoucherHash(_voucher);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return
            recoverSigner(ethSignedMessageHash, _voucher.signature) ==
            _voucher.user;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /* 
    **********************************
            INTERNAL OVERRIDES                 
    **********************************
    */

    // function _msgSender()
    //     internal
    //     view
    //     virtual
    //     override(Context, ERC2771Context)
    //     returns (address sender)
    // {
    //     return super._msgSender();
    // }

    // function _msgData()
    //     internal
    //     view
    //     virtual
    //     override(Context, ERC2771Context)
    //     returns (bytes calldata)
    // {
    //     return super._msgData();
    // }
}
