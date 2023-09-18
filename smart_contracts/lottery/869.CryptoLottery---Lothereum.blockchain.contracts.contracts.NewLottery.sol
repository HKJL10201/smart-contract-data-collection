pragma solidity ^0.5.16;

contract NewLottery {

    event BettingPhase();
    /*struct Bet {
       uint256 _stava; 
    }*/


    address public house;
    address public better;
    string public bettingNumber;
    string public winningNumber;
    //Bet public memory _stava;
    uint256 public _stava;

    enum State { BettingPhase, Win, Loss } //bo vrednosti 0, 1 ali 2
    State public state;

    constructor() public payable {
        better = msg.sender;
        state = State.BettingPhase;  
    }

    //preverja v kakšnem stanju je runda loterije
    modifier inState(State _state) {
        require(state == _state);
        _; //nujno met
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    //z modififerjem izid loterije evaluira
    function lotteryOutcome() public inState(State.BettingPhase) {
        bool izid = compareStrings(bettingNumber, winningNumber);
        if(izid) { //1 pomeni zmaga
            state = State.Win;
        } else { //2 pomeni več sreče prihodnjič
            state = State.Loss;
        }
    }

    //stavi od 1-100
    function userInput(uint256 bet) public {
        _stava = bet;
    }

    function getterBet() public view returns (uint256) {
        return 50;
    }

    //vrne naslov pogodbe
    function getAddress() public view returns (address) {  
       address myaddress = address(this); //contract address  
       return myaddress;  
    }

    //izvedi naš bet (kliknit moraš v remixu)
    function bet() public payable {
        bettingNumber = uint2str(_stava);
        winningNumber = uint2str(rand());
    }

    //int to string conversion
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    //preveri winning in betting number kot string
    function compareStrings (string memory a, string memory b) public pure returns (bool){
       return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
	}

    //vrne naključno število med 1 in 100
    function rand() public view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
            block.number
        )));
        return ((seed - ((seed / 1000) * 1000)) % 100);
        //return 20;
    }
}