// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ITransferHelper.sol";

contract TransferHelper is ERC721Holder, ITransferHelper, ReentrancyGuard {
    address public admin;

    mapping(address => bool) private operators;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "only operator");
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender);
        _;
    }

    function operator(address _operator) public view returns (bool) {
        return operators[_operator];
    }

    function addOperator(address _operator) external onlyAdmin nonReentrant {
        operators[_operator] = true;
    }

    function removeOperator(address _operator) external onlyAdmin {
        delete operators[_operator];
    }

    function executeERC721Transfer(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _tokenId
    ) external onlyOperator nonReentrant {
        IERC721(_tokenAddress).safeTransferFrom(_from, _to, _tokenId);
    }

    function executeERC20Transfer(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOperator nonReentrant {
        IERC20(_tokenAddress).transferFrom(_from, _to, _amount);
    }

    function executeERC20TransferBack(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) external onlyOperator nonReentrant {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }

    function executeERC1155Transfer(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOperator nonReentrant {
        IERC1155(_tokenAddress).safeTransferFrom(
            _from,
            _to,
            _tokenId,
            _amount,
            ""
        );
    }
}
