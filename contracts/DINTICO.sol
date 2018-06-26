pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol';
import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract DINTToken is StandardToken {
    using SafeMath for uint256;

    string public name = "DINT Coin";
    string public symbol = "DINT";
    uint256 public decimals = 18;

    uint256 public totalSupply = 20*1000000 ether;
    uint256 public totalRaised; // total ether raised (in wei)

    uint256 public startTimestamp; // timestamp after which ICO will start
    uint256 public durationSeconds = 30*60*60*24; // 1 months

    uint256 public maxCap; // the ICO ether max cap (in wei)

    uint256 public minAmount = 1 ether; // Minimum Transaction Amount(1 DIC)

    uint256 public coinsPerETH = 682;

    mapping(uint => uint) public weeklyRewards;

    /**
     * Address which will receive raised funds 
     * and owns the total supply of tokens
     */
    address public fundsWallet;

    function DINTToken() {
        fundsWallet = 0x1660225Ed0229d1B1e62e56c5A9a9e19e004Ea4a;
        startTimestamp = 1526169600;

        balances[fundsWallet] = totalSupply;
        Transfer(0x0, fundsWallet, totalSupply);
    }

    function() isIcoOpen checkMin payable{
        totalRaised = totalRaised.add(msg.value);

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        balances[fundsWallet] = balances[fundsWallet].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

        Transfer(fundsWallet, msg.sender, tokenAmount);

        // immediately transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
    }

    function calculateTokenAmount(uint256 weiAmount) constant returns(uint256) {
        uint256 tokenAmount = weiAmount.mul(coinsPerETH);
        // setting rewards is possible only for 4 weeks
        for (uint i = 1; i <= 4; i++) {
            if (now <= startTimestamp +  (i*7 days)) {
                return tokenAmount.mul(100+weeklyRewards[i]).div(100);    
            }
        }
        return tokenAmount;
    }

    function adminAddICO(uint256 _startTimestamp, uint256 _durationSeconds, 
        uint256 _coinsPerETH, uint256 _maxCap, uint _week1Rewards,
        uint _week2Rewards, uint _week3Rewards, uint _week4Rewards) isOwner{

        startTimestamp = _startTimestamp;
        durationSeconds = _durationSeconds;
        coinsPerETH = _coinsPerETH;
        maxCap = _maxCap * 1 ether;

        weeklyRewards[1] = _week1Rewards;
        weeklyRewards[2] = _week2Rewards;
        weeklyRewards[3] = _week3Rewards;
        weeklyRewards[4] = _week4Rewards;

        // reset totalRaised
        totalRaised = 0;
    }

    modifier isIcoOpen() {
        require(now >= startTimestamp);
        require(now <= (startTimestamp + durationSeconds));
        require(totalRaised <= maxCap);
        _;
    }

    modifier checkMin(){
        require(msg.value.mul(coinsPerETH) >= minAmount);
        _;
    }

    modifier isOwner(){
        require(msg.sender == fundsWallet);
        _;
    }
}
