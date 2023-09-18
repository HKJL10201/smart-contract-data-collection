// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract VToken is ERC20, ERC20Permit, Ownable {
    uint256 public maxSupply;

    constructor(
        uint256 _maxSupply
    ) ERC20("VToken", "VT") ERC20Permit("Vtoken") {
        maxSupply = _maxSupply;
        require(maxSupply >= 1, "Max token supply must be greater than 0"); // throws error if max supply is set to 0
        require(
            maxSupply <= 10000,
            "Max token supply must be less than or equal to 10,000"
        ); // throws error if max supply is set to a number greater than 500
    }

    function mintERC20(address to, uint256 amount) public {
        uint256 total = totalSupply();
        require(
            (total + amount) <= maxSupply,
            "Number of tokens minted to this address plus tokens in circulation should be less than the max supply"
        );
        _mint(to, amount); // _mint is the building block that allows us to write ERC20 extensions that implement a supply mechanism
    }

    /*
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {}

    
    function depositWithPermit(uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
    }

    bytes32 public constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline)"
        );

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0) && to != address(0)) {
            _approve(
                from,
                _msgSender(),
                allowance(from, _msgSender()).sub(
                    amount,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
        }
    }
*/
}
