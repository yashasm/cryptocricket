pragma solidity ^0.4.17;

contract cricket{
    address owner;

    struct game{
        uint gameId;
        uint externalGameId;
        string teamA;
        string teamB;
        uint teamATotalBet;
        uint teamBTotalBet;
        uint drawTotalBet;
        uint totalBet;
        address[] teamABets;
        address[] teamBBets;
        address[] drawBets;
        uint[] teamABetValues;
        uint[] teamBBetValues;
        uint[] drawBetValues;
    }

    mapping(uint => game) public games;

    modifier restriction(){
        require(msg.sender == owner);
        _;
    }

    function cricket() public{
        owner = msg.sender;
    }

    function createGame(uint _gameId,uint _externalGameId, string _teamA, string _teamB) restriction public{
        game memory newGame = game({
            gameId:_gameId,
            externalGameId:_externalGameId,
            teamA: _teamA,
            teamB: _teamB,
            teamATotalBet:0,
            teamBTotalBet:0,
            drawTotalBet:0,
            totalBet:0,
            teamABets: new address[](0),
            teamBBets: new address[](0),
            drawBets: new address[](0),
            teamABetValues: new uint[](0),
            teamBBetValues: new uint[](0),
            drawBetValues: new uint[](0)
        });
        games[_gameId] = newGame;
    }

    function placeBet(uint _gameId, string _team) payable public{
        require(msg.value >= 0.01 ether);
        game storage fetchedGame = games[_gameId];
        if(keccak256(fetchedGame.teamA) == keccak256(_team)){
            fetchedGame.teamABets.push(msg.sender);
            fetchedGame.teamABetValues.push(msg.value);
            fetchedGame.teamATotalBet += msg.value;
        }
        else if(keccak256(fetchedGame.teamB) == keccak256(_team)){
            fetchedGame.teamBBets.push(msg.sender);
            fetchedGame.teamBBetValues.push(msg.value);
            fetchedGame.teamBTotalBet += msg.value;
        }else{
            fetchedGame.drawBets.push(msg.sender);
            fetchedGame.drawBetValues.push(msg.value);
            fetchedGame.drawTotalBet += msg.value;
        }
        fetchedGame.totalBet += msg.value;
    }


    function percent(uint numerator, uint denominator, uint precision) public pure  returns(uint quotient) {
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    function finalizeMatch(uint _gameId, string winner) restriction public{
        game fetchedGame = games[_gameId];
        uint i;
        if(keccak256(fetchedGame.teamA) == keccak256(winner)){

            for (i=0;i<fetchedGame.teamABets.length;i++){
                fetchedGame.teamABets[i].transfer(fetchedGame.teamABetValues[i] + ((percent(fetchedGame.teamABetValues[i],
                    fetchedGame.teamATotalBet,3) * (fetchedGame.teamBTotalBet + fetchedGame.drawTotalBet))/1000));

            }
        }else if(keccak256(fetchedGame.teamB) == keccak256(winner)){
            for( i=0;i<fetchedGame.teamBBets.length;i++){

                fetchedGame.teamBBets[i].transfer(fetchedGame.teamBBetValues[i] + ((percent(fetchedGame.teamBBetValues[i],
                    fetchedGame.teamBTotalBet,3) * (fetchedGame.teamATotalBet + fetchedGame.drawTotalBet))/1000));

            }
        }else{
            for( i=0;i<fetchedGame.drawBets.length;i++){
                fetchedGame.drawBets[i].transfer(percent((fetchedGame.drawBetValues[i] * (fetchedGame.teamBTotalBet + fetchedGame.teamATotalBet)),
                                                    fetchedGame.drawTotalBet,4));

                fetchedGame.drawBets[i].transfer(fetchedGame.drawBetValues[i] + ((percent(fetchedGame.drawBetValues[i],
                    fetchedGame.drawTotalBet,3) * (fetchedGame.teamATotalBet + fetchedGame.teamBTotalBet))/1000));
            }
        }
        delete(games[_gameId]);
    }

}
