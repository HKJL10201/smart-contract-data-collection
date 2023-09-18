//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Ticket/TicketFactory.sol";
import "./Ticket/TicketBeacon.sol";

/// @notice Ownable contract used to manage the Lottery system - the factory and the beacon contracts
contract LotteryManager is Ownable {
    TicketBeacon public ticketBeacon;
    TicketFactory public ticketFactory;

    event ImplementationChanged(
        address indexed previousImplementation,
        address indexed newImplementation
    );

    event LotteryOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Ownable contract used to manage the Lottery system - the factory and the beacon contracts
    /// @param implementation_ The address of the Ticket implementation that is initially used by the beacon
    /// @param winnerPicker_ The VRF Consumer contract address that will be used to fetch the random numbers for selecting a winning ticket
    function setupLottery(address implementation_, address winnerPicker_)
        external
        onlyOwner
    {
        ticketBeacon = new TicketBeacon(implementation_);
        ticketFactory = new TicketFactory(address(ticketBeacon), winnerPicker_);
    }

    /// @notice Changes the address of the logic/implementation contract used in the lottery system
    /// @param newImplementation The address of the new implementation that is going to be used by the ticket proxies
    /// @custom:advice In future add a timer (fe. of 2 weeks) before the actual change happens so users can get informed and ready
    function changeImplementation(address newImplementation)
        external
        onlyOwner
    {
        address previousImplementation = ticketBeacon.implementation();
        ticketBeacon.upgradeTo(newImplementation);
        emit ImplementationChanged(previousImplementation, newImplementation);
    }

    /// @notice Calls the deployTicketProxy function of the factory
    function deployTicketProxy(
        string calldata _name,
        string calldata _symbol,
        uint64 _start,
        uint64 _end,
        uint128 _ticketPrice
    ) external onlyOwner {
        ticketFactory.deployTicketProxy(
            _name,
            _symbol,
            _start,
            _end,
            _ticketPrice
        );
    }

    /// @notice Calls the deployTicketProxyDeterministic function of the factory
    function deployTicketProxyDeterministic(
        string calldata _name,
        string calldata _symbol,
        uint64 _start,
        uint64 _end,
        uint128 _ticketPrice,
        uint128 _salt
    ) external onlyOwner {
        ticketFactory.deployTicketProxyDeterministic(
            _name,
            _symbol,
            _start,
            _end,
            _ticketPrice,
            _salt
        );
    }

    /// @notice Transfers both the beacon and factory ownership to a single account
    /// @param newOwner The address of the new Lottery manager
    /// @dev It is highly recommended that the new manager is a contract (multisig wallet, DAO etc) that implements the same method
    function transferLotteryOwnership(address newOwner) external onlyOwner {
        ticketBeacon.transferOwnership(newOwner);
        ticketFactory.transferOwnership(newOwner);
        emit LotteryOwnershipTransferred(address(this), newOwner);
    }
}
