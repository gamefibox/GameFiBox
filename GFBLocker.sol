pragma solidity ^0.5.17;

import './IERC20.sol';
import './SafeMath.sol';
import './owned.sol';

// Token Locker for tech team & presale
contract GFBLocker is owned{
    using SafeMath for uint256;

    uint256 constant public TECH_TOTAL_SHARE = 100000*10**18;
    uint256 constant public PRESALE_TOTAL_SHARE = 50000*10**18;

    event CoinWithdrawn(address indexed addr, uint256 amount);

    address payable tech_wallet;

    mapping (address => uint256) presale_balance;
    mapping (address => uint256) presale_withdraw_tokens;

    IERC20 gfb;

    uint256 public tech_withdraw_tokens;


    uint40 public online_time;

    constructor(address payable gfbContractAddress, address payable techAddress) public {

    	gfb = IERC20(gfbContractAddress);

	tech_wallet = techAddress;

	tech_withdraw_tokens = 0;

        online_time = uint40(block.timestamp+365*86400);
    }

    function _setOnlineTime(uint40 ts) onlyOwner public {

	online_time = ts;
    }

    function _addPresaleUser(address account, uint256 volume) onlyOwner public {

	require(account != address(0) && volume > 0, "Invalid parameters.");

	presale_balance[account] = presale_balance[account].add(volume);
    }
 

    function tech_withdraw() public {

	require(msg.sender == tech_wallet, "only authorized user.");

	uint256 amount = this.getTechAvailableAmount();
	
        require(amount > 0, "No available coins.");

	uint256 gfb_balance = gfb.balanceOf(address(this));

        require(gfb_balance >= amount, "No GFB left for withdrawing");

	gfb.transfer(msg.sender, amount);

	tech_withdraw_tokens = tech_withdraw_tokens.add(amount);

	emit CoinWithdrawn(msg.sender, amount);
    }

    function presale_withdraw() public {

	require(presale_balance[msg.sender] > 0, "only authorized user.");

	uint256 amount = this.getPresaleAvailableAmount(msg.sender);
	
        require(amount > 0, "No available coins.");

	uint256 gfb_balance = gfb.balanceOf(address(this));

        require(gfb_balance >= amount, "No GFB left for withdrawing");

	gfb.transfer(msg.sender, amount);

	presale_withdraw_tokens[msg.sender] = presale_withdraw_tokens[msg.sender].add(amount);

	emit CoinWithdrawn(msg.sender, amount);
    }

    /*
        Only external call
    */
    function getTechAvailableAmount() view external returns(uint256) {
	uint256 ts = block.timestamp;
	if(ts < online_time)
		return 0;
	uint256 time_span = ts - online_time;
	uint256 amount = time_span.div(86400).mul(TECH_TOTAL_SHARE).div(360);
	if(amount > TECH_TOTAL_SHARE)
		amount = TECH_TOTAL_SHARE;
	if(amount <= tech_withdraw_tokens)
		amount = 0;
	else
		amount = amount.sub(tech_withdraw_tokens);
	return amount;
    }

    function getPresaleAvailableAmount(address account) view external returns(uint256) {
	
	require(presale_balance[account]>0, "has been withdrawn or has no presale tokens.");

	uint256 ts = block.timestamp;
	if(ts < online_time)
		return 0;
	uint256 amount = presale_balance[account].mul(2).div(5);
	uint256 time_span = ts - online_time;
	amount = amount.add(time_span.div(86400).div(30).mul(presale_balance[account]).div(20));
	if(amount > presale_balance[account])
		amount = presale_balance[account];
	if(amount <= presale_withdraw_tokens[account])
		amount = 0;
	else
		amount = amount.sub(presale_withdraw_tokens[account]);
	return amount;
    }
}

