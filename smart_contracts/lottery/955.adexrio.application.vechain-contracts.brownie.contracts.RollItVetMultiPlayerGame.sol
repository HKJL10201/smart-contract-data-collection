// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract Extension {
    function blake2b256(bytes memory data)
        public
        view
        virtual
        returns (bytes32);

    function blockID(uint256 num) public view virtual returns (bytes32);

    function blockTotalScore(uint256 num) public view virtual returns (uint64);

    function blockTime(uint256 num) public view virtual returns (uint256);

    function blockSigner(uint256 num) public view virtual returns (address);

    function totalSupply() public view virtual returns (uint256);

    function txProvedWork() public view virtual returns (uint256);

    function txID() public view virtual returns (bytes32);

    function txBlockRef() public view virtual returns (bytes8);

    function txExpiration() public view virtual returns (uint256);
}

contract RollItVetMultiPlayerGame {
    address owner;
    address treasury;

    bool public gamePaused;

    address extension_native = 0x0000000000000000000000457874656E73696F6e;
    Extension ext = Extension(extension_native);

    enum GameStatus {
        COMPLETE,
        AWAITING_GAME_CRITERIA_MET,
        CRITERIA_MET_AWAITING_LOTTERY
    }
    enum PlayerGameStatus {
        PENDING_GAME_COMPLETION,
        WITHDREW_FROM_GAME,
        WIN,
        LOSE
    }

    GameHouseRules public gameHouseRules;
    Game[] games;
    uint256 public gamesTotalCount;

    uint256 public completeGamesOnlyTotalCount;
    uint256 public awaitingGameCriteriaMetOnlyTotalCount;
    uint256 public criteriaMetAwaitingLotteryOnlyTotalCount;

    event GameCreatedEvent(
        uint256 indexed gameId,
        address indexed player,
        uint256 indexed dateTime
    );

    event PlayerJoinedGameEvent(
        uint256 indexed gameId,
        address indexed player,
        uint256 indexed dateTime
    );

    event PlayerLeftGameEvent(
        uint256 indexed gameId,
        address indexed player,
        uint256 indexed dateTime
    );

    event GameAwaitingLotteryEvent(
        uint256 indexed gameId,
        GameStatus indexed status,
        uint256 indexed dateTime
    );

    //can this be status changed
    event GameCompletedEvent(
        uint256 indexed gameId,
        address indexed player,
        uint256 indexed dateTime,
        uint256 winningPayout,
        bytes32 transactionId,
        uint256 auditRecordDrawId
    );

    struct GameHouseRules {
        uint8 houseCommissionPercent;
        uint256 minBetSize;
        uint8 minGamePlayers;
        uint256 minimumAuditGameVetAmount;
    }
    struct GameCreatorSettings {
        uint8 minGamePlayers;
        uint256 gameBetSize;
        uint256 createdDateTime;
        bool isAuditEnabled;
    }
    struct Game {
        uint256 id;
        GameStatus status;
        GameCreatorSettings settings;
        uint256 auditRecordDrawId;
        uint256 winningPayout;
        uint256 totalGameWagers;
        uint256 playerArrayCount;
        uint256 eligiblePlayerCount;
    }
    //gameid => player address to array int
    mapping(uint256 => mapping(address => uint256)) _players;
    mapping(uint256 => mapping(uint256 => PlayerGameEntry)) players;

    struct PlayerGameEntry {
        address payable playerAddress;
        uint256 betsize;
        PlayerGameStatus playerGameStatus;
        bool inCurrentGame;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    modifier onlyTreasury {
        require(
            msg.sender == treasury,
            "Only treasury can call this function."
        );
        _;
    }
    modifier gameIsActive {
        require(gamePaused != true, "Game is currently in the paused state");
        _;
    }

    modifier gameIsValid(
        uint8 _minGamePlayers,
        bool _isAuditEnabled,
        uint256 _gameBetSize
    ) {
        require(
            msg.sender != 0x0000000000000000000000000000000000000000,
            "Caller is not a valid wallet address"
        );
        require(
            msg.value >= gameHouseRules.minBetSize,
            "Value is not above the minimum bet size"
        );
        require(
            _minGamePlayers >= gameHouseRules.minGamePlayers,
            "Game players should be above the house rules setting"
        );
        require(
            (_isAuditEnabled &&
                _minGamePlayers * _gameBetSize >
                gameHouseRules.minimumAuditGameVetAmount) || (!_isAuditEnabled),
            "Audit game"
        );
        _;
    }
    modifier canLeaveGame(uint256 _gameId) {
        require(
            players[_gameId][_players[_gameId][msg.sender]].inCurrentGame,
            "Player is not found participating in this game"
        );
        require(
            games[_gameId].status == GameStatus.AWAITING_GAME_CRITERIA_MET,
            "Game is no longer in the awaiting game criteria met phase"
        );
        _;
    }
    modifier canJoinExistingGame(uint256 _gameId) {
        require(
            msg.sender != 0x0000000000000000000000000000000000000000,
            "Caller is not a valid wallet address"
        );
        require(
            msg.value == games[_gameId].settings.gameBetSize,
            "Bet size does not match the game creators bet size"
        );
        require(
            games[_gameId].status == GameStatus.AWAITING_GAME_CRITERIA_MET,
            "Game is not in the awaiting critieria met state"
        );
        require(
            msg.value >= gameHouseRules.minBetSize,
            "Value is not above the minimum bet size"
        );
        require(
            _players[_gameId][msg.sender] == 0 &&
                !players[_gameId][_players[_gameId][msg.sender]].inCurrentGame,
            "Player is or was participating in the current game. Not eligible to join."
        );
        require(
            games[_gameId].eligiblePlayerCount <
                games[_gameId].settings.minGamePlayers,
            "Game is at maximum players"
        );
        _;
    }
    modifier isGameInLotteryState(uint256 _gameId) {
        require(
            games[_gameId].status == GameStatus.CRITERIA_MET_AWAITING_LOTTERY,
            "Game is not in the awaiting for lottery state"
        );
        _;
    }
    modifier isNoAuditGame(uint256 _gameId) {
        require(
            !games[_gameId].settings.isAuditEnabled,
            "Game creator settings game has random.org audits disabled"
        );
        _;
    }

    modifier isAuditGame(uint256 _gameId) {
        require(
            games[_gameId].settings.isAuditEnabled,
            "Game creator settings game has random.org audits enabled"
        );
        _;
    }
    modifier playerIsInGame(uint256 _gameId, address _playerAddress) {
        require(
            msg.sender != 0x0000000000000000000000000000000000000000,
            "Caller is not a valid wallet address"
        );
        require(
            _players[_gameId][_playerAddress] != 0 &&
                players[_gameId][_players[_gameId][_playerAddress]]
                    .inCurrentGame,
            "Player is not in the current game"
        );
        _;
    }

    // Create a new contract
    constructor() payable {
        owner = msg.sender;
        treasury = msg.sender;

        gamesTotalCount = 0;

        completeGamesOnlyTotalCount = 0;
        awaitingGameCriteriaMetOnlyTotalCount = 0;
        criteriaMetAwaitingLotteryOnlyTotalCount = 0;

        gameHouseRules = GameHouseRules({
            houseCommissionPercent: 3,
            minBetSize: 1000000000000000000, // equivalent of 1 VET
            minGamePlayers: 2,
            minimumAuditGameVetAmount: 30000000000000000000 // equivalent of 30 VET
        });
    }

    function createGame(uint8 _minGamePlayers, bool _isAuditEnabled)
        public
        payable
        gameIsActive()
        gameIsValid(_minGamePlayers, _isAuditEnabled, msg.value)
    {
        Game memory newGame =
            Game({
                id: gamesTotalCount,
                status: GameStatus.AWAITING_GAME_CRITERIA_MET,
                settings: GameCreatorSettings({
                    gameBetSize: msg.value,
                    createdDateTime: block.timestamp,
                    minGamePlayers: _minGamePlayers,
                    isAuditEnabled: _isAuditEnabled
                }),
                winningPayout: 0,
                totalGameWagers: msg.value,
                eligiblePlayerCount: 1,
                playerArrayCount: 1,
                auditRecordDrawId: 0
            });

        games.push(newGame);

        // map player to position 1, using position 0 for default not present
        _players[newGame.id][msg.sender] = newGame.playerArrayCount;
        players[newGame.id][newGame.playerArrayCount] = PlayerGameEntry({
            playerAddress: payable(msg.sender),
            betsize: msg.value,
            playerGameStatus: PlayerGameStatus.PENDING_GAME_COMPLETION,
            inCurrentGame: true
        });

        gamesTotalCount++;
        awaitingGameCriteriaMetOnlyTotalCount++;
        emit GameCreatedEvent(newGame.id, msg.sender, block.timestamp);
    }

    function joinExistingGame(uint256 _gameId)
        public
        payable
        gameIsActive()
        canJoinExistingGame(_gameId)
    {
        Game storage existingGame = games[_gameId];

        existingGame.playerArrayCount++;
        existingGame.eligiblePlayerCount++;

        //second player should be mapped to position 2
        _players[_gameId][msg.sender] = existingGame.playerArrayCount;
        players[_gameId][existingGame.playerArrayCount] = PlayerGameEntry({
            playerAddress: payable(msg.sender),
            betsize: msg.value,
            playerGameStatus: PlayerGameStatus.PENDING_GAME_COMPLETION,
            inCurrentGame: true
        });

        existingGame.totalGameWagers += msg.value;

        emit PlayerJoinedGameEvent(_gameId, msg.sender, block.timestamp);

        if (gameMeetsCriteriaToStart(_gameId)) {
            existingGame.status = GameStatus.CRITERIA_MET_AWAITING_LOTTERY;

            criteriaMetAwaitingLotteryOnlyTotalCount++;

            awaitingGameCriteriaMetOnlyTotalCount--;

            emit GameAwaitingLotteryEvent(
                _gameId,
                existingGame.status,
                block.timestamp
            );
        }
    }

    function gameMeetsCriteriaToStart(uint256 _gameId)
        internal
        view
        returns (bool)
    {
        Game storage existingGame = games[_gameId];
        return
            existingGame.eligiblePlayerCount ==
            existingGame.settings.minGamePlayers;
    }

    function leaveGame(uint256 _gameId)
        public
        gameIsActive()
        canLeaveGame(_gameId)
    {
        Game storage existingGame = games[_gameId];
        existingGame.status = GameStatus.AWAITING_GAME_CRITERIA_MET;

        PlayerGameEntry storage entry =
            players[_gameId][_players[_gameId][msg.sender]];

        existingGame.totalGameWagers =
            existingGame.totalGameWagers -
            entry.betsize;

        existingGame.eligiblePlayerCount--;

        entry.playerGameStatus = PlayerGameStatus.WITHDREW_FROM_GAME;
        entry.playerAddress.transfer(entry.betsize);

        emit PlayerLeftGameEvent(_gameId, msg.sender, block.timestamp);
    }

    function setMinimumAuditGameVet(uint256 _amount) public onlyOwner {}

    function setTreasuryAddress(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function getPausedMode() public view returns (bool) {
        return gamePaused;
    }

    function setPauseModeEnabled() public onlyOwner {
        gamePaused = true;
    }

    function setPauseModeDisabled() public onlyOwner {
        gamePaused = false;
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function setGameWinnerAudit(
        uint256 gameId,
        address playerWinner,
        uint256 auditRecordDrawId
    )
        public
        onlyOwner()
        isGameInLotteryState(gameId)
        isAuditGame(gameId)
        playerIsInGame(gameId, playerWinner)
    {
        Game storage existingGame = games[gameId];

        for (uint256 i = 1; i <= existingGame.playerArrayCount; i++) {
            PlayerGameEntry storage entry = players[gameId][i];
            if (
                entry.playerGameStatus ==
                PlayerGameStatus.PENDING_GAME_COMPLETION &&
                entry.inCurrentGame
            ) {
                if (entry.playerAddress == playerWinner) {
                    entry.playerGameStatus = PlayerGameStatus.WIN;

                    uint256 houseCommissionWitholdings =
                        (existingGame.totalGameWagers *
                            gameHouseRules.houseCommissionPercent) / 100;

                    payable(treasury).transfer(houseCommissionWitholdings);

                    existingGame.winningPayout =
                        existingGame.totalGameWagers -
                        houseCommissionWitholdings;

                    entry.playerAddress.transfer(existingGame.winningPayout);
                } else {
                    entry.playerGameStatus = PlayerGameStatus.LOSE;
                }
            }
        }

        existingGame.auditRecordDrawId = auditRecordDrawId;
        existingGame.status = GameStatus.COMPLETE;

        completeGamesOnlyTotalCount++;

        criteriaMetAwaitingLotteryOnlyTotalCount--;

        emit GameCompletedEvent(
            gameId,
            playerWinner,
            block.timestamp,
            existingGame.winningPayout,
            ext.txID(),
            existingGame.auditRecordDrawId
        );
    }

    function setGameWinnerNoAudit(uint256 gameId, address playerWinner)
        public
        onlyOwner()
        isGameInLotteryState(gameId)
        isNoAuditGame(gameId)
        playerIsInGame(gameId, playerWinner)
    {
        Game storage existingGame = games[gameId];

        for (uint256 i = 1; i <= existingGame.playerArrayCount; i++) {
            PlayerGameEntry storage entry = players[gameId][i];
            if (
                entry.playerGameStatus ==
                PlayerGameStatus.PENDING_GAME_COMPLETION &&
                entry.inCurrentGame
            ) {
                if (entry.playerAddress == playerWinner) {
                    entry.playerGameStatus = PlayerGameStatus.WIN;

                    uint256 houseCommissionWitholdings =
                        (existingGame.totalGameWagers *
                            gameHouseRules.houseCommissionPercent) / 100;

                    payable(treasury).transfer(houseCommissionWitholdings);

                    existingGame.winningPayout =
                        existingGame.totalGameWagers -
                        houseCommissionWitholdings;

                    entry.playerAddress.transfer(existingGame.winningPayout);
                } else {
                    entry.playerGameStatus = PlayerGameStatus.LOSE;
                }
            }
        }

        existingGame.status = GameStatus.COMPLETE;

        completeGamesOnlyTotalCount++;

        criteriaMetAwaitingLotteryOnlyTotalCount--;

        emit GameCompletedEvent(
            gameId,
            playerWinner,
            block.timestamp,
            existingGame.winningPayout,
            ext.txID(),
            0
        );
    }

    function getEligiblePlayersForLotteryByActiveGameId(uint256 id)
        public
        view
        returns (address[] memory playerWallets)
    {
        require(gamesTotalCount > 0, "No games to return");
        Game memory thisGame = games[id];
        //offset for not using first index
        uint8 offset = 1;
        uint256 insertIndex = 0;
        playerWallets = new address[](thisGame.eligiblePlayerCount);

        for (uint256 i = offset; i <= thisGame.playerArrayCount; i++) {
            PlayerGameEntry memory entry = players[id][i];
            if (
                entry.playerGameStatus ==
                PlayerGameStatus.PENDING_GAME_COMPLETION &&
                entry.inCurrentGame
            ) {
                playerWallets[insertIndex] = entry.playerAddress;
                insertIndex++;
            }
        }
    }

    function getGameById(uint256 id)
        public
        view
        returns (
            uint256 gameId,
            GameStatus gameStatus,
            uint256 gameTotalWagers,
            uint256 gameTotalEligiblePlayers,
            uint256 gameWinningPayout,
            address gameWinnerAddress,
            uint8 gcsMinGamePlayers,
            uint256 gcsGameBetSize,
            bool gcsIsAuditEnabled
        )
    {
        require(gamesTotalCount > 0, "No games to return");
        Game memory thisGame = games[id];

        gameId = thisGame.id;
        gameStatus = thisGame.status;
        gameTotalWagers = thisGame.totalGameWagers;
        gameTotalEligiblePlayers = thisGame.eligiblePlayerCount;
        gameWinningPayout = thisGame.winningPayout;
        gameWinnerAddress = getGameWinnerAddress(id);

        // GameCreatorSettings
        gcsMinGamePlayers = thisGame.settings.minGamePlayers;
        gcsGameBetSize = thisGame.settings.gameBetSize;
        gcsIsAuditEnabled = thisGame.settings.isAuditEnabled;
    }

    function getGameWinnerAddress(uint256 gameId)
        public
        view
        returns (address gameWinningAddress)
    {
        Game memory thisGame = games[gameId];

        if (thisGame.status == GameStatus.COMPLETE) {
            for (uint256 pi = 1; pi <= thisGame.playerArrayCount; pi++) {
                PlayerGameEntry memory entry = players[gameId][pi];
                if (
                    entry.playerGameStatus == PlayerGameStatus.WIN &&
                    entry.inCurrentGame
                ) {
                    gameWinningAddress = entry.playerAddress;
                    break;
                }
            }
        }
    }

    function getGamesByStatus(GameStatus _status)
        public
        view
        returns (
            uint256[] memory gameIds,
            GameStatus[] memory gameStatus,
            uint256[] memory gameTotalWagers,
            uint256[] memory gameTotalEligiblePlayers,
            uint256[] memory gameWinningPayout,
            address[] memory gameWinnerAddress,
            uint8[] memory gcsMinGamePlayers,
            uint256[] memory gcsGameBetSize,
            bool[] memory gcsIsAuditEnabled
        )
    {
        uint256 gamesWithRequestedStatusSize = 0;

        if (_status == GameStatus.COMPLETE) {
            gamesWithRequestedStatusSize = completeGamesOnlyTotalCount;
        } else if (_status == GameStatus.AWAITING_GAME_CRITERIA_MET) {
            gamesWithRequestedStatusSize = awaitingGameCriteriaMetOnlyTotalCount;
        } else if (_status == GameStatus.CRITERIA_MET_AWAITING_LOTTERY) {
            gamesWithRequestedStatusSize = criteriaMetAwaitingLotteryOnlyTotalCount;
        }

        gameIds = new uint256[](gamesWithRequestedStatusSize);
        gameStatus = new GameStatus[](gamesWithRequestedStatusSize);
        gameTotalWagers = new uint256[](gamesWithRequestedStatusSize);
        gameTotalEligiblePlayers = new uint256[](gamesWithRequestedStatusSize);
        gameWinningPayout = new uint256[](gamesWithRequestedStatusSize);
        gameWinnerAddress = new address[](gamesWithRequestedStatusSize);

        // GameCreatorSettings
        gcsMinGamePlayers = new uint8[](gamesWithRequestedStatusSize);
        gcsGameBetSize = new uint256[](gamesWithRequestedStatusSize);
        gcsIsAuditEnabled = new bool[](gamesWithRequestedStatusSize);

        uint256 returnIndexPosition = 0;
        for (uint256 i = 0; i < games.length; i++) {
            Game memory thisGame = games[i];

            address gameWinningAddress = getGameWinnerAddress(i);

            if (thisGame.status == _status) {
                gameIds[returnIndexPosition] = thisGame.id;
                gameStatus[returnIndexPosition] = thisGame.status;
                gameTotalWagers[returnIndexPosition] = thisGame.totalGameWagers;
                gameTotalEligiblePlayers[returnIndexPosition] = thisGame
                    .eligiblePlayerCount;
                gameWinningPayout[returnIndexPosition] = thisGame.winningPayout;
                gameWinnerAddress[returnIndexPosition] = gameWinningAddress;

                // GameCreatorSettings

                gcsMinGamePlayers[returnIndexPosition] = thisGame
                    .settings
                    .minGamePlayers;
                gcsGameBetSize[returnIndexPosition] = thisGame
                    .settings
                    .gameBetSize;
                gcsIsAuditEnabled[returnIndexPosition] = thisGame
                    .settings
                    .isAuditEnabled;
                returnIndexPosition++;
            }
        }
    }
}
