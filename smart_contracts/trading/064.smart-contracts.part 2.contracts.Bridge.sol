// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC20Base.sol";
import "./ERC20Base.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bridge is Ownable {
    using ECDSA for bytes32;

    address private validator;
    mapping(uint256 => bool) public allowedChains;
    mapping(string => bool) public allowedTokens;
    mapping(string => address) public tokenAddresses;
    mapping(bytes => bool) public signatures;

    event SwapInitialized(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 chainId,
        string _symbol
    );

    constructor() {
        validator = msg.sender;
    }

    function addToken(address _tokenAddress) external onlyOwner {
        string memory _symbol = ERC20Base(_tokenAddress).symbol();
        allowedTokens[_symbol] = true;
        tokenAddresses[_symbol] = _tokenAddress;
    }

    function removeToken(string memory _symbol) external onlyOwner {
        delete allowedTokens[_symbol];
        delete tokenAddresses[_symbol];
    }

    function addChain(uint256 chainId) external onlyOwner {
        allowedChains[chainId] = true;
    }

    function removeChain(uint256 chainId) external onlyOwner {
        delete allowedChains[chainId];
    }

    function swap(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 chainId,
        string memory _symbol
    ) external {
        require(allowedTokens[_symbol], "This token is not allowed");
        require(allowedChains[chainId] == true, "This chain is not allowed");

        address _token = tokenAddresses[_symbol];
        IERC20Base(_token).burn(msg.sender, amount);

        emit SwapInitialized(msg.sender, to, amount, nonce, chainId, _symbol);
    }

    function redeem(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 chainId,
        string memory _symbol,
        bytes calldata signature
    ) external {
        require(allowedTokens[_symbol], "This token is not allowed");
        require(!signatures[signature], "Reentrancy prevented");

        bytes32 message = keccak256(
            abi.encodePacked(from, to, amount, nonce, chainId, _symbol)
        );
        require(_verify(message, signature, validator), "wrong signature");
        signatures[signature] = true;
        address _token = tokenAddresses[_symbol];

        IERC20Base(_token).mint(to, amount);
    }

    function _verify(
        bytes32 data,
        bytes calldata signature,
        address account
    ) internal pure returns (bool) {
        return data.toEthSignedMessageHash().recover(signature) == account;
    }
}

// Deployed to: 0xBE56c7cc235E25C9873e55Df8fc1A2434d74ef2B -rinkeby
// 0x0bD592b52998EED1C5Df0cc2b20a33e87F7655E3 -  binance
