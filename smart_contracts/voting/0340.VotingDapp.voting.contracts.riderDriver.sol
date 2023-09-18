pragma solidity ^0.4.0;

/*
Simple escrow contract that mediates disputes using a trusted arbiter
*/
contract Rider {
    
     enum State {RIDE_READY, RIDE_WAITING,RIDE_BOOKED,RIDE_ACCEPTED,RIDE_CANCELLED,RIDE_STARTED,RIDE_ENDED,RIDE_COMPLETE}
    State public riderState;
    
    modifier riderOnly() { require(msg.sender == rider); _; }
    modifier arbiterOnly() {require(msg.sender == arbiter); _;}
    modifier driverOnly() {require(msg.sender == driver); _;}
    modifier checkBalance() {  require(rider.balance > msg.value); _;}
    modifier inState(State expectedState) { require(riderState == expectedState); _; }
    
    address public rider;
    address public driver;
    address public arbiter;
    
    function Rider(address _rider, address _driver,address _arbiter){
        rider = _rider;
        driver=_driver;
        arbiter = _arbiter;
    }
    
    function bookRide(uint cost) riderOnly  inState(State.RIDE_READY)  {
        require(rider.balance > cost);
        riderState = State.RIDE_WAITING;
    }
    function confirmDriver() driverOnly inState(State.RIDE_WAITING) {
        riderState=State.RIDE_BOOKED;
    }
    function confirmRide() riderOnly inState(State.RIDE_BOOKED) payable {
        riderState=State.RIDE_ACCEPTED;
    }
    function cancelRide() riderOnly driverOnly arbiterOnly inState(State.RIDE_ACCEPTED) {
        rider.transfer(this.balance);
        riderState=State.RIDE_CANCELLED;
    }
    function rideStarted() driverOnly inState(State.RIDE_ACCEPTED) {
        riderState=State.RIDE_STARTED;
    }
    function rideEnded() driverOnly inState(State.RIDE_STARTED) {
        riderState=State.RIDE_ENDED;
    }
    function confirmPayment() riderOnly arbiterOnly inState(State.RIDE_ENDED) {
        driver.transfer(this.balance);
        riderState=State.RIDE_COMPLETE;
    }
}
