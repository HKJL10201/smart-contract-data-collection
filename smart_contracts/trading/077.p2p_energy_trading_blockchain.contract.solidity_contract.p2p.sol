// greater than 0.5.10
pragma solidity ^0.5.10;

contract p2p {

    int availableEnergy;
    int demandEnergy;
    int consumedEnergy;

    int priceWh;

    int numberOfConsumers;
    int numberOfProsumers;

    int maxBalanceForThisCycle;

    event MyEvent(int value);
    event Message(string message);

    // This is a special function called the fallback.
    // The fallback function declared payable enables other contracts to
    // send Ether by send, transfer, or call.
    function () external payable {}

    // Constructor code is only run when the contract
    // is created
    constructor() public {
        availableEnergy = 0;
        demandEnergy = 0;
        consumedEnergy = 0;
        priceWh = 1;
        numberOfConsumers = 0;
        numberOfProsumers = 0;
        maxBalanceForThisCycle = 0;
    }

    function updateEnergy(int _newEnergy, int _pastEnergy) public {
        if(_newEnergy < 0){ //Consumer case
            if(numberOfConsumers == 0) {
                consumedEnergy = 0;
            }
            numberOfConsumers = numberOfConsumers + 1;

            if(_pastEnergy <= 0){
                updateDemandEnergy(-_newEnergy, -_pastEnergy);
            }
            else if(_pastEnergy > 0){
                updateAvailableEnergy(0, _pastEnergy);
                updateDemandEnergy(-_newEnergy,0);
            }
            emit MyEvent(1);
        }

        if(_newEnergy > 0){ //Prosumer case

            numberOfProsumers = numberOfProsumers + 1;

            if(_pastEnergy >= 0){
                updateAvailableEnergy(_newEnergy, _pastEnergy);
            }
            else if(_pastEnergy < 0){
                updateDemandEnergy(0, -_pastEnergy);
                updateAvailableEnergy(_newEnergy,0);
            }
            emit MyEvent(2);
        }
    }

    function deductProsumer() public {
        numberOfProsumers = numberOfProsumers - 1;

        if(numberOfProsumers == 0){
            maxBalanceForThisCycle = 0;
            consumedEnergy = 0;
        }
    }

    function prosumer(address payable _user, int _injectedEnergy) public {
        numberOfProsumers = numberOfProsumers - 1;
        int part = getPercentage(_injectedEnergy);
        emit MyEvent(part*maxBalanceForThisCycle);
        sendEther(_user, part*maxBalanceForThisCycle);
    }

    function getMaxBalanceForThisCycle() public view returns (int){
        return maxBalanceForThisCycle;
    }


    function getNumberConsumer() public view returns (int) {
        return numberOfConsumers;
    }

    function getNumberProsumer() public view returns (int) {
        return numberOfProsumers;
    }

    function getConsumedEnergy() public view returns (int){
        return consumedEnergy;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPercentage(int _energyInjected) public view returns (int){
        return (int((_energyInjected*100)/availableEnergy));
    }

    function sendEther(address payable recipient, int _amount) public payable {
        uint toSend = uint(_amount);
        recipient.call.value(toSend/100)('');

        if(numberOfProsumers == 0){
            maxBalanceForThisCycle = 0;
            consumedEnergy = 0;
            //emit Message('Reseting values for next cycle.');
        }
    }

    function consumer(address payable _user, int _consumeEnergy) public {
        if( ((availableEnergy - consumedEnergy) > 0) && (numberOfProsumers > 0)){
            if( (availableEnergy/numberOfConsumers) >= -_consumeEnergy ){
                consumedEnergy = consumedEnergy - _consumeEnergy;
                emit MyEvent(int(-_consumeEnergy));
            }
            else {
                consumedEnergy = consumedEnergy + (availableEnergy/numberOfConsumers);
                emit MyEvent(int(availableEnergy/numberOfConsumers));
            }
        }
        else{
            numberOfConsumers = numberOfConsumers -1;
            emit MyEvent(0);
        }
    }



    function convEnergyToEther(int _energy) public view returns (int){
        return priceWh*_energy;
    }

    function updateAvailableEnergy(int _injectedEnergy, int _pastInjectedEnergy) public payable{
        availableEnergy += (_injectedEnergy - _pastInjectedEnergy);
    }

    function updateDemandEnergy(int _consumeEnergy, int _pastConsumeEnergy) public payable{
        demandEnergy += (_consumeEnergy - _pastConsumeEnergy);
    }

    function getAvailableEnergy() public view returns (int){
        return availableEnergy;
    }

    function getDemandEnergy() public view returns (int){
        return demandEnergy;
    }

    function deposit(int _enough, int _amount) payable public {
        maxBalanceForThisCycle = maxBalanceForThisCycle + _amount;
        require(msg.value == uint(_amount));
        if(_enough == 1){
            numberOfConsumers = numberOfConsumers - 1;
        }
        // nothing else to do!
    }

    function reset() public {
        availableEnergy = 0;
        demandEnergy = 0;
        consumedEnergy = 0;
        priceWh = 1;
        numberOfConsumers = 0;
        numberOfProsumers = 0;
        maxBalanceForThisCycle = 0;
    }

}
