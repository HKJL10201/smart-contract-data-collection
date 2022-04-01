pragma solidity ^0.4.15;

/*
    Copyright 2017, Konstantin Viktorov (XRED Foundation)
    Copyright 2017, Jorge Izquierdo (Aragon Foundation)
    Copyright 2017, Jordi Baylina (Giveth)

    Based on MiniMeToken.sol from https://github.com/Giveth/minime
 */

contract Controlled {
    address public controller;

    function Controlled() {
      controller = msg.sender;
    }

    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController {
      require(msg.sender == controller);
      _;
    }

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}
