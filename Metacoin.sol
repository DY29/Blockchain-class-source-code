pragma solidity ^0.4.18;

import "./ConvertLib.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract MetaCoin {

	// 계정별 metacoin의 양
	// balanced[address] =>address의 metacoin 양
	mapping (address => uint) balances;

	// 이벤트
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	// 생성자
	constructor() public {
		// 계약을 호출한 계정(= 해당 계약의 소유자) 에 10000개의 메타 코인을 배정
		balances[tx.origin] = 10000;  // tx.origin 은 계정 생성됐을때 생성한 사용자의 주소
		// ㄴ balances[msg.sender]=10000;과 동일.
	}
	// 코인 전송
	// sendCoin을 호출하는 사람이 가지고 있는 메타 코인을 
	// 리시버 계정에게 amount 만큼을 전달

	function sendCoin(address receiver, uint amount) public returns(bool sufficient) {

		// 검증을 통해 부정을 방지
		if (balances[msg.sender] < amount) return false;
		balances[msg.sender] -= amount;
		balances[receiver] += amount;
		
		// 코인 전송 결과를 이벤트로 전달
		emit Transfer(msg.sender, receiver, amount);
		return true;
	}
	// 코인의 가치를 이더로 환산해서 반환
	function getBalanceInEth(address addr) public view returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}
	// 계정이 보유하고 있는 메타코인의 갯수를 반환
	function getBalance(address addr) public view returns(uint) {
		return balances[addr];
	}
}

// 코인 != 이더
// 
