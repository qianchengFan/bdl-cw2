// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract s1935167 {
    address owner;

    bool public timer = false;
    bool public time_passed = false;
    uint private start_Time = block.timestamp;
    uint private current_time;
    uint private time_Limit = 1 minutes;


    struct player {
        address player_address;
        uint balance;
        bool exist;
        bytes32 seed;
        game_state state;
        bool validated;
    }

    event Withdrawal(address customer);
    event Add_balance(address customer);
    player public player1;
    player public player2;
    player null_player = player1;
    mapping(address => player )public players;

    enum game_state{
        free,
        commited,
        playing
    }
    uint public result;

    function check_time()public returns(bool){
        current_time =  block.timestamp;
        if (current_time-start_Time > time_Limit){
            time_passed = true;
            return true;
        }
        return false;
    }


    /*
    This method can let player to do registration, and store at least enough balance for 1 round of game.
    */
    function register() public payable returns (string memory) {
        require(msg.value >=3000000000000000000 && !players[msg.sender].exist,"you should not registered before or you at least should send 3ETH to regist");
        player memory p = player(msg.sender,msg.value,true,keccak256(abi.encodePacked(msg.sender)),game_state.free,false);
        players[msg.sender]  = p;
        return "you are successfully registed";
    }

    function add_balance() public payable returns(uint){
        require (players[msg.sender].exist && msg.value > 0,
            "you need to be a registered player, and send value >0");
        players[msg.sender].balance += msg.value;
        emit Add_balance(msg.sender);
        return players[msg.sender].balance;
    }

    function commit_seed(bytes32 new_seed) public{
        require(players[msg.sender].exist && players[msg.sender].state == game_state.free);
        players[msg.sender].seed = new_seed;
        players[msg.sender].state = game_state.commited;
    }

    function join_game() public{
        require(check_balance(players[msg.sender].player_address) && players[msg.sender].state == game_state.commited && (!player1.exist || !player2.exist),
        "you need to commit first or wait the last game finish or store enough balance");
        if(player1.exist){
            player2 = players[msg.sender];
            players[msg.sender].state = game_state.playing;
            timer = true;
            start_Time =  block.timestamp;
        }
        else{
            player1 = players[msg.sender];
            players[msg.sender].state = game_state.playing;
        }
    }

    function validate(string memory message)public returns (bool){
        require (player1.exist && player2.exist && (players[msg.sender].player_address == player1.player_address
        || players[msg.sender].player_address == player2.player_address),"validation only for playing players, and the game should have 2 players joined");
        if (players[msg.sender].player_address == player1.player_address){
            if (keccak256(abi.encode(message))==player1.seed){
                player1.validated = true;
                player1.seed = (keccak256(abi.encodePacked(player1.seed,message)));
                return true;
            }
            else{
                return false;
            }
        }
        else{
            if (keccak256(abi.encode(message))==player2.seed){
                player2.validated = true;
                player2.seed = (keccak256(abi.encodePacked(player2.seed,message)));
                return true;
            }
            else{
                return false;
            }
        }
    }

    function start_game()public{
        require(player1.validated && player2.validated,"both players need to be validated");
        result = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number,player1.seed,player2.seed))) % (6);
        result += 1;
        players[player1.player_address].state = game_state.free;
        players[player2.player_address].state = game_state.free;
        if (result>3){
            result -= 3;
            players[player1.player_address].balance -= result*1000000000000000000;
            players[player2.player_address].balance += result*1000000000000000000;
        }
        else{
            players[player2.player_address].balance -= result*1000000000000000000;
            players[player1.player_address].balance += result*1000000000000000000;
        }
        player1 = null_player;
        player2 = null_player;
        timer = false;
    }

    function players_ready() public view returns (bool){
        require(player1.exist && player2.exist);
        return true;
    }

    /*
    used when there is no player2 joined and player 1 want to leave
    */
    function exit_from_wait_join()public{
        require(players[msg.sender].exist && player1.player_address == msg.sender && !player2.exist);
        players[player1.player_address].state = game_state.free;
        player1 = null_player;
    }

    /*
    used when the other player not validate for a long time
    */
    function exit_from_wait_validation()public{
        require(timer && players[msg.sender].exist && (player1.player_address == msg.sender || player2.player_address == msg.sender));
        if (check_time()){
            if (player1.player_address == msg.sender && !player2.validated && player1.validated){
                players[player2.player_address].balance -= 3*1000000000000000000;
                players[player1.player_address].balance += 3*1000000000000000000;
                players[player1.player_address].state = game_state.free;
                players[player2.player_address].state = game_state.free;
                player1 = null_player;
                player2 = null_player;
                timer = false;
            }
            if (player2.player_address == msg.sender && !player1.validated && player2.validated){
                players[player2.player_address].balance += 3*1000000000000000000;
                players[player1.player_address].balance -= 3*1000000000000000000;
                players[player1.player_address].state = game_state.free;
                players[player2.player_address].state = game_state.free;
                player1 = null_player;
                player2 = null_player;
                timer = false;
            }

        }
        players[msg.sender].state = game_state.free;
        player1.player_address = address(0);
        players[player1.player_address].exist = false;
    }

    function timeout_for_others() public{
        require(timer && players[msg.sender].exist && player1.player_address != msg.sender && player2.player_address != msg.sender);
        if (check_time()){
            players[player2.player_address].balance -= 3*1000000000000000000;
            players[player1.player_address].balance -= 3*1000000000000000000;
            players[msg.sender].balance += 6*1000000000000000000;
            players[player1.player_address].state = game_state.free;
            players[player2.player_address].state = game_state.free;
            player1 = null_player;
            player2 = null_player;
            timer = false;
        }
    }



    function check_balance(address player_address)public view returns(bool){
        require(players[player_address].exist);
        if (players[player_address].balance >=3*1000000000000000000){
            return true;
        }
        else{
            return false;
        }
    }

    function withdraw() public {
        require(players[msg.sender].state != game_state.playing);
        uint b = players[msg.sender].balance;
        players[msg.sender].balance = 0;
        payable(msg.sender).transfer(b);
        emit Withdrawal(msg.sender);
    }
}
