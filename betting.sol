pragma solidity ^0.5.2;

contract IEF_Betting {
    
    struct PlayerBet {
        uint8 bet;
        uint256 timestamp;
    }
    
    struct Bet {
        address betOwner;
        mapping(address => PlayerBet) bets;
        address[] players; 
        uint256 ETHAmount;
        uint256 latestClosage;
        uint256 openedAt;
        bool isOpen;
        int8 randomResult;
    }
    
    mapping(uint256 => Bet) public betting;
    uint256 public betId;
    
    constructor() public {
        betId = 0;
    }
    
    function createBet(uint256 ethAmount, uint256 maxDaysOpen) public returns (uint256) {
        betId++;
        Bet memory bet = Bet({
            betOwner:msg.sender,
            ETHAmount:ethAmount,
            players: new address[](0),
            // convert days to seconds
            latestClosage: now + (maxDaysOpen * 24 * 60 * 60),
            openedAt: now,
            isOpen:true,
            randomResult:-1
        });
        betting[betId] = bet;
        return betId;
    }
    
    function placeBet(uint256 id, uint8 val) payable public returns (bool){
        // TODO: return refunds if bet is already closed
        
        require(betting[id].isOpen);
        // check if bet does not already exist
        require(betting[id].bets[msg.sender].timestamp == 0);
        // check if the amount sent is the correct amount
        require(msg.value == 1e18 * betting[id].ETHAmount);
        
        PlayerBet memory bet = PlayerBet({
           bet:val,
           timestamp:now
        });
        
        betting[id].bets[msg.sender] = bet;
        // add the player to the bet 
        betting[id].players.push(msg.sender);
        
        return true; 
    }
    
    function closeBet(uint256 id) public returns (bool) {
        // TODO: determine the random number 0/1
        // TODO: reward the winners of the bet with the ether
        
        require(betting[id].isOpen);
        require(betting[id].betOwner == msg.sender);
        betting[id].isOpen = false;
        return true;
    }
    
    
    // TODO: create a timeout that automatically closes the bets
}