// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface IAnonymousVoting {

    function registerElection(
        uint256 electionId,
        address[] memory _voters, 
        uint256 start, uint256 end
    ) external;
    
    function registerTicket(
        uint256 electionId,uint256 ticket
    ) external;

    function spendTicket(
        uint256 electionId, uint256 merkleRoot,
        uint256 option, uint256 serial, bytes memory proof
    ) external;

    function getWinner(
        uint256 electionId, uint256 merkleRoot
    ) external view returns (uint256);

    function getTickets(
        uint256 electionId
    ) external view returns (uint256[] memory);
}