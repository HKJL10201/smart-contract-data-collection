// solium-disable linebreak-style
pragma solidity >=0.5.0 <0.7.0;

contract EnergyTrading {
    address creator;
    mapping(address => uint256) public balanceOf;

    constructor() public {
        creator = msg.sender;
    }

    modifier IsCreator(address _user) {
        require(_user == creator, "User not Creator!");
        _;
    }

    function SetTk(uint256 _initialSupply) public IsCreator(msg.sender) {
        balanceOf[creator] = _initialSupply; // Give the creator all initial tokens
    }

    function Deposit(address _account, uint256 _amount)
        public
        IsCreator(msg.sender)
    {
        balanceOf[_account] += _amount;
    }

    function Withdraw(address _account, uint256 _amount)
        public
        IsCreator(msg.sender)
    {
        balanceOf[_account] -= _amount;
    }

    function TransferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public IsCreator(msg.sender) {
        require(balanceOf[_from] >= _value, "Insufficient balance."); // Check if the sender has enough coins
        require(
            balanceOf[_to] + _value >= balanceOf[_to],
            "Transaction overflow!"
        ); // Check for overflows
        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
    }

    /////////////
    //   bid   //
    /////////////

    struct bid_struct {
        uint256[] volume;
        uint256[] price;
    }
    // time => type(buy/sell) => user_address => bid_struct
    mapping(string => mapping(string => mapping(address => bid_struct))) bids;

    event bid_log(
        address _user,
        string _bid_time,
        string _bid_type,
        uint256[] _volume,
        uint256[] _price
    );

    function bid(
        address _user,
        string memory _bid_time,
        string memory _bid_type,
        uint256[] memory _volume,
        uint256[] memory _price
    ) public IsCreator(msg.sender) {
        bids[_bid_time][_bid_type][_user] = bid_struct({
            volume: _volume,
            price: _price
        });
        emit bid_log(_user, _bid_time, _bid_type, _volume, _price);
    }

    event get_log(uint256[] _volume, uint256[] _price);

    function getBid(
        address _user,
        string memory _bid_time,
        string memory _bid_type
    ) public view returns (uint256[] memory, uint256[] memory) {
        bid_struct memory the_bid = bids[_bid_time][_bid_type][_user];
        return (the_bid.volume, the_bid.price);
    }

    /////////////
    //  match  //
    /////////////

    // array of collected sells and buys
    uint256[] buy_prices;
    uint256[] buy_volumes;
    address[] buy_users;
    uint256[] sell_prices;
    uint256[] sell_volumes;
    address[] sell_users;

    // array of accumulated sells and buys
    uint256[] ab_prices;
    uint256[] ab_volumes;
    address[] ab_users;
    uint256[] as_prices;
    uint256[] as_volumes;
    address[] as_users;

    // array of accumulated and ready-to-match sells and buys
    uint256[] mb_prices;
    uint256[] mb_volumes;
    address[] mb_users;
    uint256[] ms_prices;
    uint256[] ms_volumes;
    address[] ms_users;

    // array of matched sells, buys and ratios
    address[] matched_buy_users;
    uint256[] matched_buy_volumes;
    uint256[] matched_buy_ratios;
    address[] matched_sell_users;
    uint256[] matched_sell_volumes;
    uint256[] matched_sell_ratios;

    // points of intersection lines
    // intersection occurs when two lines intersect which will consist of four points
    // they are line1point1, line1point2, line2point1, and line2point1
    // in short l1p1, l1p2, l2p1, l2p2
    int256[][] line_points;

    // event that logs the sells and buys array
    event array_log(uint256[] _volume, uint256[] _price, address[] _users);

    // event that logs matched result
    event matched_log(
        bool _matched,
        uint256 _matched_volume,
        uint256 _matched_price,
        address[] _matched_buy_users,
        uint256[] _matched_buy_ratios,
        address[] _matched_sell_users,
        uint256[] _matched_sell_ratios
    );

    // matched struct to store matched data
    struct matched_struct {
        bool _matched;
        uint256 _matched_volume;
        uint256 _matched_price;
        address[] _matched_buy_users;
        uint256[] _matched_buy_ratios;
        address[] _matched_sell_users;
        uint256[] _matched_sell_ratios;
    }

    // mapping for matched result (time -> matched_struct)
    mapping(string => matched_struct) matched_result;

    //////////////////
    //  match body  //
    //////////////////
    function match_bids(address[] memory _users, string memory _bid_time)
        public
        IsCreator(msg.sender)
    {
        _clear_match_array(); // Clear array for each match event
        _combine_match_array(_bid_time, _users); // Combine bids for every user
        _accumulate_array(); // Accumulate bids
        _merge_array(); // Merge bids
        bool matched = _find_intersection(); // Finding match intersection
        _find_shares(uint256(line_points[0][1]), uint256(line_points[2][1])); // Split bids by margin

        // store matched result
        matched_result[_bid_time] = matched_struct({
            _matched: matched,
            _matched_volume: uint256(line_points[2][0]),
            _matched_price: uint256(line_points[2][1]),
            _matched_buy_users: matched_buy_users,
            _matched_buy_ratios: matched_buy_ratios,
            _matched_sell_users: matched_sell_users,
            _matched_sell_ratios: matched_sell_ratios
        });

        // emit matched result
        emit matched_log(
            matched, // match success
            uint256(line_points[2][0]), // matched volume
            uint256(line_points[2][1]), // matched price
            matched_buy_users, // buyers' addresses
            matched_buy_ratios, // buyers' bid ratios
            matched_sell_users, // sellers' addresses
            matched_sell_ratios // sellers' bid ratios
        );
    }

    // get matchresult
    function getMatchResult(string memory _bid_time)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            address[] memory,
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        matched_struct memory the_matchresult = matched_result[_bid_time];
        return (
            the_matchresult._matched,
            the_matchresult._matched_volume,
            the_matchresult._matched_price,
            the_matchresult._matched_buy_users,
            the_matchresult._matched_buy_ratios,
            the_matchresult._matched_sell_users,
            the_matchresult._matched_sell_ratios
        );
    }

    //////////////////////////////
    //  match helper functions  //
    //////////////////////////////

    // function that clear all the state variables (dynamic array)
    function _clear_match_array() private {
        // Reset dynamic arrays for match bids
        delete buy_prices;
        delete buy_volumes;
        delete buy_users;
        delete sell_prices;
        delete sell_volumes;
        delete sell_users;

        // accumulated arrays
        delete ab_prices;
        delete ab_volumes;
        delete ab_users;
        delete as_prices;
        delete as_volumes;
        delete as_users;

        // matching array
        delete mb_prices;
        delete mb_volumes;
        delete mb_users;
        delete ms_prices;
        delete ms_volumes;
        delete ms_users;

        // matched_result array
        delete matched_buy_users;
        delete matched_buy_volumes;
        delete matched_buy_ratios;
        delete matched_sell_users;
        delete matched_sell_volumes;
        delete matched_sell_ratios;

        delete line_points;
    }

    // combine match array from gathering all the user's bids
    function _combine_match_array(
        string memory _bid_time,
        address[] memory _users
    ) private {
        // users' buys
        for (uint256 i = 0; i < _users.length; i++) {
            uint256[] memory prices;
            uint256[] memory volumes;
            bid_struct memory user_buy_bids = bids[_bid_time]["buy"][_users[i]];
            prices = user_buy_bids.price;
            volumes = user_buy_bids.volume;

            for (uint256 j = 0; j < prices.length; j++) {
                buy_prices.push(prices[j]);
                buy_volumes.push(volumes[j]);
                buy_users.push(_users[i]);
            }
        }

        // users' sells
        for (uint256 i = 0; i < _users.length; i++) {
            uint256[] memory prices;
            uint256[] memory volumes;

                bid_struct memory user_sell_bids
             = bids[_bid_time]["sell"][_users[i]];
            prices = user_sell_bids.price;
            volumes = user_sell_bids.volume;

            for (uint256 j = 0; j < prices.length; j++) {
                sell_prices.push(prices[j]);
                sell_volumes.push(volumes[j]);
                sell_users.push(_users[i]);
            }
        }
    }

    // resorting all bids among users by using insertion sort algorithm
    function _sort_array() private {
        // buy
        uint256 j;
        uint256 b_price_key;
        uint256 b_volume_key;
        address b_user_key;
        for (uint256 i = 1; i < buy_prices.length; i++) {
            b_price_key = buy_prices[i];
            b_volume_key = buy_volumes[i];
            b_user_key = buy_users[i];
            j = i - 1;
            bool flag = false;
            while (j >= 0 && buy_prices[j] < b_price_key) {
                buy_prices[j + 1] = buy_prices[j];
                buy_volumes[j + 1] = buy_volumes[j];
                buy_users[j + 1] = buy_users[j];
                if (j == 0) {
                    flag = true;
                    break;
                } else {
                    j = j - 1;
                }
            }
            // avoid uint 0 - 1
            if (flag) {
                buy_prices[0] = b_price_key;
                buy_volumes[0] = b_volume_key;
                buy_users[0] = b_user_key;
            } else {
                buy_prices[j + 1] = b_price_key;
                buy_volumes[j + 1] = b_volume_key;
                buy_users[j + 1] = b_user_key;
            }
        }

        // sell
        uint256 s_price_key;
        uint256 s_volume_key;
        address s_user_key;
        for (uint256 i = 1; i < sell_prices.length; i++) {
            s_price_key = sell_prices[i];
            s_volume_key = sell_volumes[i];
            s_user_key = sell_users[i];
            j = i - 1;
            bool flag = false;
            while (j >= 0 && sell_prices[j] > s_price_key) {
                sell_prices[j + 1] = sell_prices[j];
                sell_volumes[j + 1] = sell_volumes[j];
                sell_users[j + 1] = sell_users[j];
                if (j == 0) {
                    flag = true;
                    break;
                } else {
                    j = j - 1;
                }
            }
            // avoid uint 0 - 1
            if (flag) {
                sell_prices[0] = s_price_key;
                sell_volumes[0] = s_volume_key;
                sell_users[0] = s_user_key;
            } else {
                sell_prices[j + 1] = s_price_key;
                sell_volumes[j + 1] = s_volume_key;
                sell_users[j + 1] = s_user_key;
            }
        }
    }

    // function to accumulate bids
    // after sorting, accumulate bids are required
    function _accumulate_array() private {
        uint256 curr_volume = 0;
        for (uint256 i = 0; i < buy_volumes.length; i++) {
            ab_volumes.push(buy_volumes[i]);
            ab_prices.push(buy_prices[i]);
            ab_users.push(buy_users[i]);
        }
        for (uint256 i = 0; i < ab_volumes.length; i++) {
            ab_volumes[i] += curr_volume;
            curr_volume = ab_volumes[i];
        }

        curr_volume = 0;
        for (uint256 i = 0; i < sell_volumes.length; i++) {
            as_volumes.push(sell_volumes[i]);
            as_prices.push(sell_prices[i]);
            as_users.push(sell_users[i]);
        }
        for (uint256 i = 0; i < as_volumes.length; i++) {
            as_volumes[i] += curr_volume;
            curr_volume = as_volumes[i];
        }
    }

    // apply 'OR' operation between buy and sell points,
    // make sure that both lines have same x-axis value
    // so we can apply 'find the intersection' algorithm
    // on the array.
    function _merge_array() private {
        uint256 i = 0;
        uint256 j = 0;

        bool loop1 = true;
        bool loop2 = true;

        while (loop1 && loop2) {
            if (as_volumes[j] < ab_volumes[i]) {
                mb_volumes.push(as_volumes[j]);
                mb_prices.push(ab_prices[i]);
                mb_users.push(ab_users[i]);
                j++;
                if (j == as_volumes.length) {
                    loop2 = false;
                    j--;
                }
            } else {
                mb_prices.push(ab_prices[i]);
                mb_volumes.push(ab_volumes[i]);
                mb_users.push(ab_users[i]);
                i++;
                if (i == ab_volumes.length) {
                    loop1 = false;
                    i--;
                }
            }
        }
        while (loop2) {
            mb_volumes.push(as_volumes[j]);
            mb_prices.push(ab_prices[i]);
            mb_users.push(ab_users[i]);
            j++;
            if (j == as_volumes.length) {
                loop2 = false;
                j--;
            }
        }
        while (loop1) {
            mb_volumes.push(ab_volumes[i]);
            mb_prices.push(ab_prices[i]);
            mb_users.push(ab_users[i]);
            i++;
            if (i == ab_volumes.length) {
                loop1 = false;
                i--;
            }
        }

        loop1 = true;
        loop2 = true;
        i = 0;
        j = 0;
        while (loop1 && loop2) {
            if (ab_volumes[j] < as_volumes[i]) {
                ms_volumes.push(ab_volumes[j]);
                if (i == 0) {
                    ms_prices.push(0);
                    ms_users.push(address(0));
                } else {
                    ms_prices.push(as_prices[i - 1]);
                    ms_users.push(as_users[i - 1]);
                }
                j++;
                if (j == ab_volumes.length) {
                    loop2 = false;
                    j--;
                }
            } else {
                ms_volumes.push(as_volumes[i]);
                ms_prices.push(as_prices[i]);
                ms_users.push(as_users[i]);
                i++;
                if (i == as_volumes.length) {
                    loop1 = false;
                    i--;
                }
            }
        }
        while (loop2) {
            ms_volumes.push(ab_volumes[j]);
            ms_prices.push(as_prices[i - 1]);
            ms_users.push(as_users[i - 1]);
            j++;
            if (j == ab_volumes.length) {
                loop2 = false;
                j--;
            }
        }
        while (loop1) {
            ms_volumes.push(as_volumes[i]);
            ms_prices.push(as_prices[i]);
            ms_users.push(as_users[i]);
            i++;
            if (i == as_volumes.length) {
                loop1 = false;
                i++;
            }
        }
    }

    /////////////////////////////
    //  line helper functions  //
    /////////////////////////////

    // determinant function
    function _det(int256[2] memory a, int256[2] memory b)
        private
        pure
        returns (int256)
    {
        return a[0] * b[1] - a[1] * b[0];
    }

    // given two lines (4 points), return whether
    // these two lines gives an intersection (T/F).
    function _line_intersection(
        int256[2] memory l1p1,
        int256[2] memory l1p2,
        int256[2] memory l2p1,
        int256[2] memory l2p2
    ) private pure returns (bool) {
        int256[2] memory xdiff = [l1p1[0] - l1p2[0], l2p1[0] - l2p2[0]];
        int256[2] memory ydiff = [l1p1[1] - l1p2[1], l2p1[1] - l2p2[1]];

        int256 div = _det(xdiff, ydiff);
        if (div == 0) {
            return false;
        }

        int256[2] memory d = [_det(l1p1, l1p2), _det(l2p1, l2p2)];
        int256 x = _det(d, xdiff) / div;
        int256 y = _det(d, ydiff) / div;

        bool c1 = x >= l1p1[0] && x <= l1p2[0];
        bool c2 = y <= l1p1[1] && y >= l1p2[1];
        bool c3 = x >= l2p1[0] && x <= l2p2[0];
        bool c4 = y >= l2p1[1] && y <= l2p2[1];
        if (c1 && c2 && c3 && c4) {
            return true;
        } else {
            return false;
        }
    }

    // buy and sell bids are two huge lines that formed
    // by line segments, so go through the segments
    // can determine where and which two segments intersect.
    function _find_intersection() private returns (bool) {
        bool intersection = false;
        for (uint256 i = 0; i < mb_volumes.length - 1; i++) {
            for (uint256 j = 0; j < ms_volumes.length - 1; j++) {
                if (
                    _line_intersection(
                        [int256(mb_volumes[i]), int256(mb_prices[i])],
                        [int256(mb_volumes[i + 1]), int256(mb_prices[i + 1])],
                        [int256(ms_volumes[j]), int256(ms_prices[j])],
                        [int256(ms_volumes[j + 1]), int256(ms_prices[j + 1])]
                    )
                ) {
                    line_points.push(
                        [int256(mb_volumes[i]), int256(mb_prices[i])]
                    );
                    line_points.push(
                        [int256(mb_volumes[i + 1]), int256(mb_prices[i + 1])]
                    );
                    line_points.push(
                        [int256(ms_volumes[j]), int256(ms_prices[j])]
                    );
                    line_points.push(
                        [int256(ms_volumes[j + 1]), int256(ms_prices[j + 1])]
                    );
                    intersection = true;
                }
            }
        }
        return intersection;
    }

    // once the matched price and volume are set,
    // split the ratio for the matched users.
    function _find_shares(uint256 _buy_target_price, uint256 _sell_target_price)
        private
    {
        uint256 total_volume = 0;
        for (uint256 i = 0; i < buy_volumes.length; i++) {
            if (buy_prices[i] == _buy_target_price) {
                matched_buy_users.push(buy_users[i]);
                matched_buy_volumes.push(buy_volumes[i]);
                total_volume += buy_volumes[i];
            }
        }
        for (uint256 i = 0; i < matched_buy_volumes.length; i++) {
            matched_buy_ratios.push(
                (matched_buy_volumes[i] * 100) / total_volume
            );
        }
        total_volume = 0;
        for (uint256 i = 0; i < sell_prices.length; i++) {
            if (sell_prices[i] == _sell_target_price) {
                matched_sell_users.push(sell_users[i]);
                matched_sell_volumes.push(sell_volumes[i]);
                total_volume += sell_volumes[i];
            }
        }
        for (uint256 i = 0; i < matched_sell_volumes.length; i++) {
            matched_sell_ratios.push(
                (matched_sell_volumes[i] * 100) / total_volume
            );
        }
    }

    //////////////////
    //  settlement  //
    //////////////////

    event settlement_log(
        address _seller,
        address _buyer,
        uint256 _price,
        uint256 _volume,
        uint256 _generated_vol,
        uint256 _amount
    );

    function settlement(
        address _seller,
        address _buyer,
        uint256 _price,
        uint256 _volume,
        uint256 _generated_vol,
        uint256 _amount
    ) public IsCreator(msg.sender) {
        TransferFrom(_buyer, _seller, _amount);
        emit settlement_log(
            _seller,
            _buyer,
            _price,
            _volume,
            _generated_vol,
            _amount
        );
    }
}
