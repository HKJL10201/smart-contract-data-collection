// SPDX-License-Identifier: GPL-3.0
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    IERC20 public token;
    address public manager; //manager address
    address payable[] public participants;
    address public winner;

    constructor(IERC20 _tokenaddress) {
        manager = msg.sender;
        token = _tokenaddress;
    }

    modifier onlyOwner() {
        require(msg.sender == manager);
        _;
    }

    function getTicket(uint _amount) external {
        require(_amount == (1 * 10 ** 18));
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transaction unsuccessful"
        );
        participants.push(payable(msg.sender));
    }

    function showBalance() public view onlyOwner returns (uint256) {
        return token.balanceOf(address(this));
    }

    function random() internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.number,
                        block.prevrandao,
                        block.timestamp,
                        participants.length
                    )
                )
            );
    }

    function findWinner() external onlyOwner {
        require(participants.length >= 3);
        uint rand = random();
        uint index = rand % participants.length;
        winner = participants[index];
        require(
            token.transfer(payable(winner), showBalance()),
            "Transaction unsuccessful"
        );
        participants = new address payable[](0);
    }
}
