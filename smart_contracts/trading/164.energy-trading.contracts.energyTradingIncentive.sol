pragma solidity >= 0.4.0 < 0.8.0;

contract P2PCI {
    struct Prosumer {
        address id;
        int256 status;
        uint256 balance;
        uint256 liquidityShares;
    }

    mapping (address => Prosumer) private prosumers;
    // Liquidity pool variables, keeping a 50:50 value split
    uint256 ethersReserve;
    uint256 energyReserve;
    uint256 totalLiquidity;

    // Mints liquidity shares for a particular prosumer
    function mint(address _id, uint256 _amount) private {
        prosumers[_id].liquidityShares += _amount;
        totalLiquidity += _amount;
    }

    // Burns liquidity shares for a particular prosumer
    function burn(address _id, uint256 _amount) private {
        prosumers[_id].liquidityShares -= _amount;
        totalLiquidity -= _amount;
    }

    function updateReserves(uint256 _energy, uint256 _ethers) private {
        ethersReserve = _ethers;
        energyReserve = _energy;
    }

    function getReserves() public view returns 
    (uint256 _energy, uint256 _ethers) {
        _ethers = ethersReserve;
        _energy = energyReserve;
    }

    /* Calculates the cost in ethers to trade for a certain amount 
    of energy, returns the ether cost.
    Using x * y = k, where x is the ether reserves and y is the 
    energy reserves and k is a constant.
    > (x + dx) * (y - dy) = k, rearrange to dx = (x * dy) / (y - dy) */
    function costToBuyEnergy(uint256 _energyAmount) public view 
    returns (uint256 _ethersAmountWithFee) {
        uint256 _ethersAmount = ((ethersReserve * _energyAmount) 
                                / (energyReserve - _energyAmount));        
        _ethersAmountWithFee = (_ethersAmount * 1000) / 998;
    }

    // Buy energy by trading ethers for energy in the liquidity pool
    function buyEnergy(address _from, uint256 _energyAmount) private 
    returns (bool _success) {
        _success = false;
        require(_energyAmount < energyReserve, 
                "Insufficient energy in liquidity reserves");

        uint256 _ethersAmountWithFee = costToBuyEnergy(_energyAmount);

        prosumers[_from].balance -= _ethersAmountWithFee;

        updateReserves(energyReserve - _energyAmount, 
                    ethersReserve + _ethersAmountWithFee);

        _success = true;
    }

    // Sell energy by trading energy for ethers in the liquidity pool
    function sellEnergy(address _from, uint256 _energyAmount) 
    private returns (bool _success) { 
        _success = false;

        // Using x * y = k, where x is the ether reserves and 
        // y is the energy reserves and k is a constant.
        // > (x - dx) * (y + dy) = k, 
        // rearrange to -dx = (x * dy) / (y + dy)
        uint256 _energyAmountWithFee = (_energyAmount * 998) / 1000;
        uint256 _ethersAmount = ((ethersReserve * _energyAmountWithFee) / 
                                (energyReserve + _energyAmountWithFee));

        require(_ethersAmount < ethersReserve, 
                "Insufficient ethers in liquidity reserves");
        prosumers[_from].balance += _ethersAmount;

        updateReserves(energyReserve + _energyAmount, 
                    ethersReserve - _ethersAmount);

        _success = true;
    }

    /* Add an amount of energy to the liquidity pool, also
    add a corresponing amount of ethers in order to keep 
    the value of energy in the pool the same */
    function addLiquidity(address _from, uint256 _energyAmount) public 
    returns (uint256 _newLiquidityShares) {
        // If the liquidity pool is empty, then let the energy 
        // and ethers have the same value (50:50)
        uint256 _ethersAmount;
        if (ethersReserve > 0) {
            _ethersAmount = (_energyAmount * energyReserve) / ethersReserve;
        } else {
            _ethersAmount = _energyAmount;
        }

        require(prosumers[_from].balance >= _ethersAmount, 
                "Insufficient account balance");
        prosumers[_from].balance -= _ethersAmount;

        /* Calculate the number of liquidity shares to mint via
        the geometric mean as a measure of liquidity.
        > S = (dx / x) * TL
        > S = (dy / y) * TL 
        In this case both equations give the same value as inputs
        are balanced so just use one.
        If the liquidity pool is empty then shares are equal 
        to the amount added as the value of energy and ethers 
        should be equal, would otherwise be sqrt(x * y) */
        if (totalLiquidity == 0) {
            _newLiquidityShares = _energyAmount;
        } else {
            _newLiquidityShares = ((_energyAmount * totalLiquidity) 
                                    / energyReserve);
        }

        mint(_from, _newLiquidityShares);

        updateReserves(energyReserve + _energyAmount, 
                    ethersReserve + _ethersAmount);
    }

    /* Get the value of ethers and energy that burning an
     amount of liquidity shares will provide */
    function getLiquidityWorth(uint256 _liquidityShares) public view 
    returns (uint256 _energyAmount, uint256 _ethersAmount) {
        require(_liquidityShares <= totalLiquidity, 
                "Invalid number of liquidity shares");

        /* Function for user to remove liquidity
        > dx = (S / TL) * x
        > dy = (S / TL) * y 
        If there is no liquidity then energy amounts are 0 
        (not strictly necessary because of above requirement) */
        if (totalLiquidity > 0) {
            _energyAmount = ((_liquidityShares * energyReserve) 
                                / totalLiquidity);
            _ethersAmount = ((_liquidityShares * ethersReserve) 
                                / totalLiquidity);
        } else {
            _energyAmount = 0;
            _ethersAmount = 0;
        }
    }

    /* Remove energy and ethers from liquidity pool based 
    on the number of liquidty shares provided */
    function removeLiquidity(address _to, uint256 _liquidityShares) public 
    returns (uint256 _energyAmount, uint256 _ethersAmount) {
        require(prosumers[_to].liquidityShares >= _liquidityShares, 
                "Insufficient liquidity shares");

        (_energyAmount, _ethersAmount) = getLiquidityWorth(_liquidityShares);

        require(_energyAmount > 0 && _ethersAmount > 0, 
                "Insufficient transfer amounts");
        prosumers[_to].balance += _ethersAmount;

        burn(_to, _liquidityShares);

        updateReserves(energyReserve - _energyAmount, 
                    ethersReserve - _ethersAmount);
    }

    // Process a change of status (requesting either to buy 
    // or sell energy depending on sign)
    function processRequest(address _id) private {
        bool _success = false;

        // Posisitive status = sell request, negative = buy request
        if (prosumers[_id].status > 0) {
            _success = sellEnergy(_id, uint256(prosumers[_id].status));
        } else if (prosumers[_id].status < 0) {
            _success = buyEnergy(_id, uint256(0 - prosumers[_id].status));
        }

        if (_success) {
            prosumers[_id].status = 0;
        }
    }

    function addProsumer(address _id) public {
        prosumers[_id].id = _id;
    }

    function updateStatus(address _id, int _amount) public {
        prosumers[_id].status = _amount;
        
        processRequest(_id);
    }

    function updateBalance(address _id, uint256 _amount) public {
        prosumers[_id].balance = _amount;
    }

    function addBalance(address _id, uint256 _amount) public {
        prosumers[_id].balance += _amount;
    }

    function removeBalance(address _id, uint256 _amount) public {
        prosumers[_id].balance -= _amount;
    }

    function getStatus(address _id) public view returns(int256) {
        return prosumers[_id].status;
    }

    function getBalance(address _id) public view returns(uint256) {
        return prosumers[_id].balance;
    }

    function getLiquidityShares(address _id) public view returns(uint256) {
        return prosumers[_id].liquidityShares;
    }

    // Prosumer is only registered if id element matches their id
    function isRegistered(address _id) public view returns(bool) {
        return prosumers[_id].id == _id;
    }
}


contract MainCI {
    P2PCI p2p;

    constructor (P2PCI _p2p) public {
        p2p = _p2p;
    }
    
    modifier checkRegistered() {
        require(p2p.isRegistered(msg.sender) == true, "Not registered");
        _;
    }

    modifier checkNotRegistered() {
        require(p2p.isRegistered(msg.sender) == false, "Already registered");
        _;
    }

    // Make sure a prosumer has enough ethers in their account if buying energy
    modifier checkSufficientFunds(int256 _energy) {
        if (_energy < 0) {
            require(p2p.getBalance(msg.sender) >= 
                    p2p.costToBuyEnergy(uint256(0 - _energy)),
                     "Insufficient account balance");
        }
        _;
    }

    modifier checkPositiveStatus() {
        require(p2p.getStatus(msg.sender) >= 0, "Withdrawal requires status >= 0");
        _;
    }

    modifier checkLiquidityShares(uint256 _shares) {
        require(p2p.getLiquidityShares(msg.sender) >= _shares, 
                "Insufficient liquidity shares balance");
        _;
    }

    modifier checkEnergyAmount(int256 _energy) {
        // Still allow status inputs of 0
        if (_energy != 0) {
            require(_energy >= (1 ether / 10), 
                "Energy inputs must be >= 1 energy unit, where"
                "1 energy unit = 1,000,000,000,000,000,000");
        }
        _;
    }

    function register() public checkNotRegistered {
        p2p.addProsumer(msg.sender);
    }

    function deposit() public payable checkRegistered {
        p2p.addBalance(msg.sender, msg.value);
    }

    function withdraw() public checkRegistered checkPositiveStatus {
        uint256 _balance = p2p.getBalance(msg.sender);
        msg.sender.transfer(_balance);
        p2p.updateBalance(msg.sender, 0);
    }

    function requestEnergy(int256 _energy) public checkRegistered 
    checkSufficientFunds(_energy) checkEnergyAmount(_energy) {
        p2p.updateStatus(msg.sender, _energy);
    }

    function getStatus() public view checkRegistered returns(int256) {
        return p2p.getStatus(msg.sender);
    }

    function getBalance() public view checkRegistered returns(uint256) {
        return p2p.getBalance(msg.sender);
    }

    function getLiquidityShares() public view checkRegistered 
    returns(uint256, uint256, uint256) {
        uint256 _shares = p2p.getLiquidityShares(msg.sender);
        (uint256 _energyVal, uint256 _ethersVal) = p2p.getLiquidityWorth(_shares);
        return (_shares, _energyVal, _ethersVal);
    }

    function depositLiquidity(uint256 _energy) public checkRegistered 
    checkEnergyAmount(int256(_energy)) returns(uint256) {
        return p2p.addLiquidity(msg.sender, _energy);
    }

    function withdrawLiquidity(uint256 _shares) public checkRegistered 
    checkLiquidityShares(_shares) returns(uint256, uint256) {
        return p2p.removeLiquidity(msg.sender, _shares);
    }

    function getPool() public view checkRegistered returns(uint256, uint256) {
        return p2p.getReserves();
    }

    function getEnergyPrice(uint256 _energy) public view checkRegistered 
    checkEnergyAmount(int256(_energy)) returns(uint256) {
        return p2p.costToBuyEnergy(_energy);
    }

    function getEnergyPrice() public view checkRegistered returns(uint256) {
        return p2p.costToBuyEnergy(1 ether);
    }
}