contract Flipper {
    enum GameState {noWager, wagerMade, wagerAccepted}
    GameState public currentState;
    
    modifier onlyState(GameState expectedState) { if(expectedState == currentState) { _; } else { throw; } }

    function Flipper(bytes32 targetState) {
        currentState = GameState.noWager;
    }

    function makeWager() onlyState(GameState.noWager) returns (bool) {
        
        currentState = GameState.wagerMade;
        return true;
    }

    function accepteWager() onlyState(GameState.wagerMade) returns (bool) {

        currentState = GameState.wagerAccepted;
        return true;
    }

    function resolveBet() onlyState(GameState.wagerAccepted) returns (bool) {

        currentState = GameState.noWager;
        return true;
    }
}