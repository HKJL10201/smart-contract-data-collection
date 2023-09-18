// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./token/ERC20.sol";
import "./access/Ownable.sol";

contract Incubation is ERC20, Ownable {
    constructor() ERC20("Payment Token", "PAY") {}

    mapping(address => bool) private _isExpert;

    event UpdatedExpertStatus(address _expertAddress, bool _status);

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
          * - `recipient` must be a valid expert

     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _address, uint _amount)
        public
        virtual
        override
        returns (bool)
    {
        require(_isExpert[_address], "Not a valid expert");
        return super.transfer(_address, _amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     * - `recipient` must be a valid expert
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint _amount
    ) public virtual override returns (bool) {
        require(_isExpert[_recipient], "Not a valid expert");
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * Whitelist an expert to be allowed to receive tokens
     * @dev update `_isExpert` with the address and its status
     * @param _expertAddress, address of the expert to be whitelisted
     * @param _status, status: true if Expert, false if not
     *
     */
    function whitelistExpert(address _expertAddress, bool _status)
        external
        onlyOwner
    {
        _isExpert[_expertAddress] = _status;
        emit UpdatedExpertStatus(_expertAddress, _status);
    }

    /**
     * Mint the `_amount` of tokens to the proposer
     * @param _proposer, address of the proposer to receive tokens
     * @param _amount, amount to be minted
     */
    function sendToProposer(address _proposer, uint _amount)
        external
        onlyOwner
    {
        _mint(_proposer, _amount);
    }

    /**
     * @notice returns true if address is an expert or false if not
     * @param _address, address to be checked
     * @return bool, true if expert, false if not
     */
    function isExpert(address _address) external view returns (bool) {
        return _isExpert[_address];
    }
}
