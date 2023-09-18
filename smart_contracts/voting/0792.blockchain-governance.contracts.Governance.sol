pragma solidity ^0.6.0;

/**
 * @title Governance voting
 * @notice  Core Contract to Create and manage Exposure Tokens | For giveaways
 * SPDX-License-Identifier: UNLICENSED
 */

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./Ownable.sol";

contract EXPOSURE is Ownable, IERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalSupply_;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) public {
        require(msg.sender != address(0), "Contract owner does not exist");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        setOwner(msg.sender);
        totalSupply_ = _totalSupply;
        balances[msg.sender] = balances[msg.sender].add(_totalSupply);
    }

    /**
     * @dev Get allowed amount for an account
     * @param owner address The account owner
     * @param spender address The account spender
     */
    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }

    /**
     * @dev Get totalSupply of token
     */
    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Get token balance of an account
     * @param account address The account
     */
    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Adds blacklisted check to approve
     * @return True if the operation was successful.
     */
    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @return bool success
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(_to != address(0), "No `to` address");
        require(
            _value <= balances[_from],
            "Not enough funds to make this request"
        );
        require(
            _value <= allowed[_from][msg.sender],
            "you do not have access to transfer this much funds"
        );

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @return bool success
     */
    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool)
    {
        require(_to != address(0), "No `to` address");
        require(
            _value <= balances[msg.sender],
            "Not enough funds to make this request"
        );

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}
