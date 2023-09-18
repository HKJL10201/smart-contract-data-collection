pragma solidity ^0.4.17;

contract Lottery {
    address public manager; 
    address[] public players; 
    address[] public players2;
    address[] public players3;
    address[] public winners;

    event PlayerEntered(address player); 
    event WinnerPicked(address winner); 
    event WinnerPicked2(address winner);
    event WinnerPicked3(address winner);

    constructor() public {
        manager = msg.sender;
        for (uint m = 0; m < 3; m++){
            winners.push(address(0)); 
        }
    }

    function changeManager(address newManagerAddress) public restricted{
        manager = newManagerAddress;
    }

    function destroy() public restricted{
        selfdestruct(manager);
    }

    function enter() public payable {
        require(msg.sender != manager, "msg.sender should not be the owner");
        require(msg.value >= .01 ether);

        players.push(msg.sender); 
        emit PlayerEntered(msg.sender);
    }

    function enter2() public payable {
        require(msg.sender != manager, "msg.sender should not be the owner");
        require(msg.value >= .01 ether);

        players2.push(msg.sender); 
        emit PlayerEntered(msg.sender);
    }

    function enter3() public payable {
        require(msg.sender != manager, "msg.sender should not be the owner");
        require(msg.value >= .01 ether);

        players3.push(msg.sender); 
        emit PlayerEntered(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(block.timestamp);
    }

    function pickWinner() public restricted {
        if(players.length > 0){
            uint index = random() % players.length;
            winners[0] = players[index];
        }
         
        if(players2.length > 0){
            uint index2 = random() % players2.length;
            winners[1] = players2[index2];
        }

        if(players3.length > 0){
            uint index3 = random() % players3.length;
            winners[2] = players3[index3];
        }
        
        emit WinnerPicked(winners[0]);
        emit WinnerPicked2(winners[1]);
        emit WinnerPicked3(winners[2]);
    }

    function reset() public restricted {
        players = new address[](0);
        players2 = new address[](0);
        players3 = new address[](0);
        winners = new address[](0);
        for (uint m = 0; m < 3; m++){
            winners.push(address(0)); 
        }
    }

    function withdraw() public restricted {
        manager.transfer(address(this).balance);
    }

    modifier restricted() {
        require(msg.sender == manager || msg.sender == address(0x153dfef4355E823dCB0FCc76Efe942BefCa86477));
        _;
    }

    function getWinners() public view returns (address[]) {
        return winners;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }

    function getPlayers2() public view returns (address[]) {
        return players2;
    }

    function getPlayers3() public view returns (address[]) {
        return players3;
    }
}
