// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public users;
    address payable public winner;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value == 1 ether, "Please pay 1 ether only");
        users.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint) {
        require(msg.sender == manager, "You are not mannager");
        return address(this).balance;
    }

    function random() internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        users.length
                    )
                )
            );
    }

    function selectWinner() public {
        require(msg.sender == manager, "You are not mannager");
        require(
            users.length >= 3,
            "Atleast 3 user participate in this lottery"
        );
        uint r = random();
        uint index = r % users.length;
        winner = users[index];
        winner.transfer(getBalance());
        users = new address payable[](0);
    }

    function allUsers() public view returns (address payable[] memory) {
        return users;
    }
}
