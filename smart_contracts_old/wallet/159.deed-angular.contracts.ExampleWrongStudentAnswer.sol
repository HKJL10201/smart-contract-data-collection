pragma solidity ^0.6.6;

import "./interface/IStudentAnswer.sol";
import "./interface/IStudentApplication.sol";


contract ExampleWrongStudentAnswer is IStudentAnswer, Ownable {
    bytes32 _seedAnswer;
    IStudentApplication _application;

    constructor(address application) public {
        _application = IStudentApplication(application);
    }

    function getOwner() external view override returns (address) {
        // note: the student address may be hardcoded and still the answer would pass the check. Perhaps it is good enough if the student somehow don't need protection in his answer contract
        return owner();
    }

    function getSeed() external view override returns (bytes32) {
        return _seedAnswer;
    }

    function solve(bytes32 secret, bool register) public onlyOwner {
        if (register) _application.registerAnswer(secret);
        bytes32 hint1 = _application.getHint(0);
        bytes32 hint2 = _application.getHint(1);
        _seedAnswer = hint1 ^ hint2;
    }
}
