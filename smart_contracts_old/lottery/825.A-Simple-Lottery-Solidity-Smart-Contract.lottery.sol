// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;


contract Lottery{

    mapping(address => mapping (uint256 => uint256)) public lotteryPoints ;
    // address => lotterryTimes => points
    // each 0.1 eth = 1 point 

    uint256 public numberOfParticipaits ;

    address[] public participants ;

    uint256 lotteryTimes = 1 ;

    function getFund() public payable {

        // minimum value to participates is 0.1 eth
        require(msg.value >= 10**17 , 'Funds arn\'t enough') ;

        //calcute number of participates
        if ( lotteryPoints[msg.sender][lotteryTimes] == 0 ){
            numberOfParticipaits += 1 ;
        }

        uint256 points = ( msg.value / 10**17 ) ;
        lotteryPoints[msg.sender][lotteryTimes] += points ;

        for (uint256 i ; i <= points ; i++){
            participants.push(msg.sender);
        }

        // does lottery for every 10 peoples and send prize to winner 
        if ( numberOfParticipaits == 10 ) {
            payable(participants[randMod(participants.length)]).transfer(address(this).balance) ;

            //reset the element for new lottery
            lotteryTimes +=1 ;
            delete participants ;
            numberOfParticipaits = 0 ;
        }
    }


    //generate random number
    // Initializing the state variable
    uint randNonce = 0;
    function randMod(uint _modulus) internal returns(uint){
    // increase nonce
    randNonce++; 
    return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus ;
    }

}

  
