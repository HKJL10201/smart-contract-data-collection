// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address payable[] public players;
    address payable public winner;

    receive() external payable {
        require(
            msg.value == 0.01 ether,
            "Please pay 0.01 Ether for joining lottery!"
        );
        players.push(payable(msg.sender));
    }

    constructor() {
        manager = msg.sender;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function pickWinner() public {
        require(msg.sender == manager, "You can not access");
        require(players.length >= 2, "Players are less than 2");
        players[random() % players.length].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function allPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
// 0x4D61aD764c2f45021C7f5DE4984cEE7fb069786F first
// 0x604Ed889ad0C30ecA05a246226F10031A53ED597 second
// 0x846602575cf14156458b121969a50c1187b20e85 third
// 0xE1954f24DD64514852416BcCdA0e785a1983c427 four