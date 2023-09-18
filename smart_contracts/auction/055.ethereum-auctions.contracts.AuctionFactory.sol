pragma solidity ^0.4.18;


contract AuctionFactory {
    mapping(address => string) auctions;
    mapping(string => address) assemblyLines;

    uint public fractionalCut = 0;
    address public controller = 0x0;

    modifier privileged {
        require(msg.sender == controller);
        _;
    }

    function setController(address _controller) privileged external {
        controller = _controller;
    }

    function setCut(uint _fractionalCut) privileged external {
        fractionalCut = _fractionalCut;
    }

    function getAssemblyLine(string _identifier) public view returns (address) {
        return assemblyLines[_identifier];
    }

    function addAssemblyLine(string _identifier, address _address) privileged external {
        require(assemblyLines[_identifier] == 0x0);
        assemblyLines[_identifier] = _address;
    }

    function registerAuction(string _identifier, address _address) external {
        require(msg.sender == assemblyLines[_identifier]);
        auctions[_address] = _identifier;
    }

    function getIdentifier(address _auction) public view returns (string) {
        return auctions[_auction];
    }
}