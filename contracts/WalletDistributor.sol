import "@openzeppelin/contracts/math/SafeMath.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}


contract WalletDistributor {
  using SafeMath for uint256;

  IERC20 public vToken;
  uint256 public currentPeriodIndex = 0;
  uint256 public periodTime = 30 days;
  uint256 currentPeriodStart;

  mapping(uint256 => uint256) public periodSharesRemoved;
  mapping(address => mapping (uint256 => bool)) public periodClaimed;

  constructor(address _vToken) public {
    vToken = IERC20(_vToken);
    currentPeriodStart = now;
  }

  // claim rewards per a certain period
  function claim() external {
    // update period index if need
    checkAndUpdatePeriod();
    // check if user claimed in this period
    require(!isClaimed(msg.sender), "Claimed, need wait");
    // get user share
    uint256 userShare = vToken.balanceOf(msg.sender);
    // calculate how much claim
    uint256 toClaim = toClaim(userShare);
    require(toClaim > 0, "Nothing claim");
    // set this user as claimed for this period
    periodClaimed[msg.sender][currentPeriodIndex] = true;
    // remove user share from total shares
    periodSharesRemoved[currentPeriodIndex] = periodSharesRemoved[currentPeriodIndex].add(userShare);
    // pay
    payable(msg.sender).transfer(toClaim);
  }

  // helper for update period
  function checkAndUpdatePeriod() internal {
    if(isNeedUpdatePeriod()){
      currentPeriodIndex = currentPeriodIndex + 1;
      currentPeriodStart = now;
    }
  }

  // VIEW functions

  // calculate how much user earn
  function earned(address user) public view returns(uint256){
    uint256 userShare = vToken.balanceOf(user);
    return toClaim(userShare);
  }

  // helper for calculate user earn by user share
  function toClaim(uint256 userShare) internal view returns(uint256){
    uint256 totalRewards = address(this).balance;
    uint256 sharesRemoved = periodSharesRemoved[currentPeriodIndex];

    uint256 totalShares = vToken.totalSupply().sub(sharesRemoved);

    if(totalRewards == 0 || userShare == 0){
      return 0;
    }else{
      return totalRewards.mul(userShare.div(10**9)).div(totalShares.div(10**9));
    }
  }

  // check if user claimed for this period
  function isClaimed(address user) public view returns(bool){
    return periodClaimed[msg.sender][currentPeriodIndex];
  }

  // check if need update period
  function isNeedUpdatePeriod() public view returns(bool){
    return now >= currentPeriodStart + periodTime;
  }

  // receive ETH
  fallback() external payable {}
}
