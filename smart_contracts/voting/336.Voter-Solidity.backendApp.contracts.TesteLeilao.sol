pragma solidity ^0.5.0;
import "./Leilao.sol";

contract TesteLeilao is Leilao {
    uint time;

    constructor(
        string memory contractName,
        uint targetAmountEth,
        uint durationInMin,
        address payable beneficiaryAddress
    )
        Leilao(contractName, targetAmountEth, durationInMin, beneficiaryAddress)
        public
    {

    }

    function currentTime() internal view returns(uint) {
        return time;
    }

    function setCurrentTime(uint newTime) public {
        time = newTime;
    }
}