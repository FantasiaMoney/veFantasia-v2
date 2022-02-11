import "@openzeppelin/contracts/math/SafeMath.sol";

contract VTokenToTokenViewHelper {
  using SafeMath for uint256;

  function calculateDeposit(uint256 balanceBefore, uint256 balanceAfter)
    public
    view 
    returns(uint256)
  {
    uint256 deposit = balanceBefore > balanceAfter
    ? balanceBefore.sub(balanceAfter)
    : balanceAfter.sub(balanceBefore);

    return deposit;
  }

  // return amount of token to withdraw
  // more time hold more close rate 1 to 1
  function calculateReturn(
     uint256 duration,
     uint256 _startTime,
     uint256 balanceBefore,
     uint256 balanceAfter
  )
    external
    view
    returns(uint256)
  {
    uint256 _amount = calculateDeposit(balanceBefore, balanceAfter);

    if(block.timestamp >= _startTime + duration) {
      return _amount;
    }
    else{
      return _amount.mul(block.timestamp.sub(_startTime)).div(duration);
    }
  }
}
