pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IMint.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/ILDManager.sol";


contract VTokenSale is Ownable {
  using SafeMath for uint256;

  address payable public devFee;
  address payable public charityFee;

  address public ldManager;
  address public token;
  address public vTokenMinter;

  uint256 public devFeePercent = 30;
  uint256 public charityFeePercent = 30;
  uint256 public ldManagerPercent = 40;

  IUniswapV2Router02 public Router;

  event Buy(address indexed user, uint256 amount);

  /**
  * @dev constructor
  *
  * @param _token         token address
  * @param _vTokenMinter  vTokenMinter address
  * @param _devFee        Address for receive ETH
  * @param _charityFee    Address for receive ETH
  * @param _ldManager     Address of ldManager
  * @param _router        Uniswap v2 router
  */
  constructor(
    address _token,
    address _vTokenMinter,
    address payable _devFee,
    address payable _charityFee,
    address _ldManager,
    address _router
    )
    public
  {
    token = _token;
    vTokenMinter = _vTokenMinter;
    devFee = _devFee;
    charityFee = _charityFee;
    ldManager = _ldManager;
    Router = IUniswapV2Router02(_router);
  }

  /**
  * @dev buy tokens for msg.sender
  *
  */
  function buy() public payable {
    buyFor(msg.sender);
  }

  /**
  * @dev buy tokens for address
  *
  */
  function buyFor(address _to) public payable {
    // not allow buy 0
    require(msg.value > 0, "Zerro input");
    // calculate amount of morebtc to send
    uint256 sendAmount = getSalePrice(msg.value);

    // split ETH
    (uint256 devFeeAmount,
     uint256 charityFeeAmount,
     uint256 ldManagerAmount) = calcualteToSplit(msg.value);

    if(devFeeAmount > 0)
      devFee.transfer(devFeeAmount);

    if(charityFeeAmount > 0)
      charityFee.transfer(charityFeeAmount);

    if(ldManagerAmount > 0)
      ILDManager(ldManager).addLiquidity.value(ldManagerAmount)();

    // mint vtoken to user
    IMint(vTokenMinter).mint(_to, sendAmount);

    // event
    emit Buy(_to, sendAmount);
  }

  /**
  * @dev return sale price from token
  */
  function getSalePrice(uint256 _amount) public view returns(uint256) {
    address[] memory path = new address[](2);
    path[0] = Router.WETH();
    path[1] = token;
    uint256[] memory res = Router.getAmountsOut(_amount, path);
    return res[1];
  }

  /**
  * @dev return split amount
  */
  function calcualteToSplit(uint256 _amount)
   public
   view
   returns(
     uint256 devFeeAmount,
     uint256 charityFeeAmount,
     uint256 ldManagerAmount
   )
  {
    devFeeAmount = _amount.div(100).mul(devFeePercent);
    charityFeeAmount = _amount.div(100).mul(charityFeePercent);
    ldManagerAmount = _amount.div(100).mul(ldManagerPercent);
  }

  /**
  * @dev owner can uodate split amount
  */
  function setSplit(
    uint256 _devFeePercent,
    uint256 _charityFeePercent,
    uint256 _ldManagerPercent
  )
   external
   onlyOwner
  {
    uint256 total = _devFeePercent.add(_charityFeePercent).add(_ldManagerPercent);
    require(total == 100, "Wrong total");

    devFeePercent = _devFeePercent;
    charityFeePercent = _charityFeePercent;
    ldManagerPercent = _ldManagerPercent;
  }

  /**
   * @dev fallback function
   */
  receive() external payable  {
    buy();
  }
}
