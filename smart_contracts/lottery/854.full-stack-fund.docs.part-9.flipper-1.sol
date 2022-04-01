contract Flipper {
    enum GameState {noWager, wagerMade, wagerAccepted}
    GameState public currentState;
    
    function Flipper(bytes32 targetState) {
        currentState = GameState.noWager;
    }

    function transitionGameState(bytes32 targetState) returns (bool) {
        if (targetState == "noWager") {
            currentState = GameState.noWager;
            return true;
        }
        else if (targetState == "wagerMade") {
            currentState = GameState.wagerMade;
            return true;
        }
        else if (targetState == "wagerAccepted") {
            currentState = GameState.wagerAccepted;
            return true;
        }
    }
}