캐쉬백 

pragma solidity ^0.4.25;

contract OpenEgCoin {
    // 상태 변수
    string  public name;        // 이름 ("OpenEgCoin")
    string  public symbol;      // 단위 ("oc")
    uint8   public decimals;    // 소수점이하의 자리수 (0)
    uint256 public totalSupply; // 총 발행량 (10000)

    // 계정별 잔액
    mapping (address => uint256) public balanceOf;
    // 블랙 리스트 여부
    mapping (address => bool) public blacklist;
    // 캐쉬백 비율
    mapping (address => uint8) public cashbackRate;

    // 계약을 생성한 계정 (계약 소유자)
    address public owner; 

    // 수식자 (계약 소유자 전용 기능)
    modifier onlyOwner() {
        if (msg.sender != owner) revert("계약 소유자 전용 기능입니다.");
        _;
    }

    // 이벤트
    // 생략...

    // 생성자 -> 상태 변수 초기화
    constructor (uint256 _supply, string _name, string _symbol, uint8 _decimals) public {
        totalSupply = _supply;
        name        = _name;
        symbol      = _symbol;
        decimals    = _decimals;

        // 전체 발행량을 계약 소유자에게 할당
        balanceOf[msg.sender] = _supply;
    }

    // 블랙 리스트 등록 
    function insertBlacklist(address _addr) public onlyOwner {
        blacklist[_addr] = true;
    }

    // 블랙 리스트 삭제
    function deleteBlacklist(address _addr) public onlyOwner {
        blacklist[_addr] = false;
    }

    // 캐시백 비율을 설정
    function setCashbackRate(uint8 _rate) public {
        if (_rate <= 0) _rate = 0;
        if (_rate > 100) _rate = 100;

        cashbackRate[msg.sender] = _rate;
    }

    // 송금
    function transfer(address _to, uint256 _value) public {
        if (_value < 0) revert("마이너스 금액은 송금할 수 없어요.");
        if (balanceOf[msg.sender] < _value) revert("잔액 보다 많은 금액은 송금할 수 없어요.");

        if (blacklist[msg.sender]) {
            // 보내는 사람이 블랙 리스트인 경우
        } else if (blacklist[_to]) {
            // 받는 사람이 블랙 리스트인 경우
        } else {
            // 받는 사람(상점)이 캐쉬백 비율을 설정해 둔 경우
            // 캐쉬백 금액을 계산
            uint256 cashback = 0;
            if (cashbackRate[_to] > 0) {
                cashback = _value * uint256(cashbackRate[_to]) / 100;
            }

            balanceOf[msg.sender] -= (_value - cashback);
            balanceOf[_to] += (_value - cashback);
        }
    }
}
