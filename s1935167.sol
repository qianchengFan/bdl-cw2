// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract s1935167 {
    struct player {
        address player_address;
        uint balance;
        bool exist;
        game_state state;
    }

    event Pay_fee(address sender);
    event Withdrawal(address customer);

    player player1;
    player player2;
    uint public last_roll;
    mapping(address => player )public players;


    enum game_state{
        free,
        playing
    }
    
    function register() public payable returns (string memory) {
        require(msg.value >=3000000000000000000);
        if (!players[msg.sender].exist){
            player memory p = player(msg.sender,msg.value,true,game_state.free);
            players[msg.sender]  = p;
            return "you are successfully registed";
        }
        else{
            return "you already registed";
        }
    }

    function add_balance() public payable returns(uint){
        require (players[msg.sender].exist && msg.value > 0,
            "you need to be a registered player, and send value >0");
        players[msg.sender].balance += msg.value;
        return players[msg.sender].balance;
    }

    function roll_dice() public returns (uint amount) {
        last_roll = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % (6-1);
        last_roll = last_roll+1;
        return last_roll;
}

    function play_game() public payable returns(string memory){
        require (players[msg.sender].exist && players[msg.sender].balance >=3000000000000000000,
            "you need to be a registered player, and have at least 3 ether");
        if (!players[msg.sender].exist){
            return "please register first";
        }
        else{
            if (!player1.exist){
                player1 = players[msg.sender];
                players[msg.sender].state = game_state.playing;
                return "you are player1, waiting for another player to join";
            }
            else{
                player2 = players[msg.sender];
                roll_dice();
                uint need_pay;
                players[player1.player_address].state = game_state.free;
                if (last_roll>3){
                    need_pay = last_roll-3;
                    pay_fee(need_pay,player1.player_address,player2.player_address);
                    return "you are player 2,player2 wins";
                }
                else{
                    pay_fee(last_roll,player2.player_address,player1.player_address);
                    return "you are player 1,player1 wins";
                }
            }
        }
    }

    function pay_fee(uint value, address sender, address receiver)public returns (bool){
        if (players[sender].balance < value*1000000000000000000){//sometimes gas fee will make it lose a little bit
            value = players[sender].balance;
            players[sender].balance = 0;
            players[receiver].balance += value;
            //payable(receiver).transfer(value);
            }
        else{
            players[sender].balance -= value*1000000000000000000;
            players[receiver].balance += value*1000000000000000000;
        }
        emit Pay_fee(receiver);
    }

    function check_balance(address player_address)public view returns(bool){
        require(players[player_address].exist);
        if (players[player_address].balance >=3){
            return true;
        }
        else{
            return false;
        }
    }

    function withdraw() public {
        uint b = players[msg.sender].balance;
        players[msg.sender].balance = 0;
        payable(msg.sender).transfer(b);
        emit Withdrawal(msg.sender);
    }
}
