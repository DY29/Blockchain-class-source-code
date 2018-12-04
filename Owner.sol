회원관리 

pragma solidity ^0.4.25;

// 계약의 소유자를 관리하는 계약
contract Owner {
    // 계약 소유자의 주소를 가지는 상태 변수
    address public owner;

    // 계약 소유자 변경 이벤트
    event EvtTransferownership(address oldaddr, address newaddr);

    // 계약 소유자로 제한(한정)하는 수식자
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("계약 소유자 전용 기능입니다.");
        }
        _;
    }

    // 생성자 
    // 계약을 생성한 계정을 owner에게 할당
    constructor () public {
        owner = msg.sender; 
    }

    // 계약 소유자는 계약의 소유권을 다른 계정으로 이전할 수 있음
    function trasferOwnership(address _newaddr) onlyOwner public {
        address _oldaddr = owner;
        owner = _newaddr;

        emit EvtTransferownership(_oldaddr, _newaddr);
    }
}

// 회원 관리 계약 
contract Member is Owner {
    // 회원 등급 정보 구조체를 정의
    struct MemberGrade {
        string  gradeName;        // 회원 등급 이름
        uint256 minTradingCount;  // 최소 구매 회수
        uint256 minTradingAmount; // 최소 구매 금액
        int8    cashbackRate;     // 등급별 할인율
    }

    // 회원의 거래 이력 정보 구조체를 정의
    struct History {
        uint256 tradingCount;  // 구매 회수
        uint256 tradingAmount; // 구매 금액
        uint256 gradeIndex;    // 회원 등급
    }

    // 상태 변수
    address public coin; // 멤버쉽을 적용할 코인 계약 주소
    MemberGrade[] public grades; // 멤버쉽 정책
    mapping(address=>History) public tradingHistory; // 회원별 거래 이력

    // 특정 코인 계약에서만 사용할 수 있도록 제한 (수식자)
    modifier onlyCoin() {
        if (msg.sender == coin) _;
    }

    // 특정 코인 계약 주소를 등록(설정)
    function setCoin(address _addr) onlyOwner public {
        coin = _addr;
    }

    // 멤버쉽 정책 추가
    function pushGrade(string _gradeName, uint256 _minTradingCount, uint256 _minTradingAmount, int8 _cashbackRate) onlyOwner public {
        grades.push(
            MemberGrade({ gradeName: _gradeName, minTradingCount: _minTradingCount, minTradingAmount: _minTradingAmount, cashbackRate: _cashbackRate })
        );
    }

    // 회원의 거래 이력 및 등급 갱신
    // 지정된 코인 계약에서만 호출할 수 있도록 제한 = onlyCoin
    function updateTradingHistory(address _member, uint256 _amount) onlyCoin public {
        tradingHistory[_member].tradingCount += 1;
        tradingHistory[_member].tradingAmount += _amount;

        uint256 gradeIndex;
        for (uint i = 0; i < grades.length; i ++) {
            if (tradingHistory[_member].tradingCount  >= grades[i].minTradingCount &&
                tradingHistory[_member].tradingAmount >= grades[i].minTradingAmount) {
                gradeIndex = i;
            }
        }

        tradingHistory[_member].gradeIndex = gradeIndex;
    }

    // 특정 회원의 캐시백 비율을 반환
    function getCashbackRate(address _member) public view returns (int8 cashbackRate) {
        cashbackRate = grades[tradingHistory[_member].gradeIndex].cashbackRate;
    }
}

contract OpenEgCoin is Owner {
    // 상태 변수
    string  public name;        // 이름 ("OpenEgCoin")
    string  public symbol;      // 단위 ("oc")
    uint8   public decimals;    // 소수점이하의 자리수 (0)
    uint256 public totalSupply; // 총 발행량 (10000)

    // 계정별 잔액
    mapping (address => uint256) public balanceOf;
    // 블랙 리스트 여부
    mapping (address => bool) public blacklist;
    // 멤버쉽을 적용한 회원
    mapping (address => Member) public membership;

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

    // 멤버쉽 적용 
    function setMembership(Member _member) public {
        membership[msg.sender] = _member;
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
            // 캐쉬백 금액을 계산
            uint256 cashback = 0;
            if (membership[_to] > address(0)) {
                cashback = _value * uint256(membership[_to].getCashbackRate(msg.sender)) / 100;
                membership[_to].updateTradingHistory(msg.sender, _value);
            }
            
            balanceOf[msg.sender] -= (_value - cashback);
            balanceOf[_to] += (_value - cashback);
        }
    }
}
