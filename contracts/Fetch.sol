pragma solidity ^0.6.2;

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ISale.sol";
import "./interfaces/IConvert.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Fetch is Ownable {
  using SafeMath for uint256;

  struct Deposit {
    uint256 balanceBefore;
    uint256 balanceAfter;
    uint256 time;
  }

  mapping (address => Deposit[]) public depositsPerUser;

  address public WETH;

  address public dexRouter;

  address public token;

  address public vToken;

  address public sale;

  uint256 public percentToDex = 50;

  uint256 public percentToSale = 50;

  uint256 public reserveSplit = 20;

  address public tokenToVToken;

  /**
  * @dev constructor
  *
  * @param _WETH                  address of Wrapped Ethereum token
  * @param _dexRouter             address of UNI v2 DEX
  * @param _token                 address of OHM token
  * @param _sale                  sale
  * @param _tokenToVToken         token to vToken converter
  * @param _vToken                not transferable vote token
  */
  constructor(
    address _WETH,
    address _dexRouter,
    address _token,
    address _sale,
    address _tokenToVToken,
    address _vToken
    )
    public
  {
    WETH = _WETH;
    dexRouter = _dexRouter;
    token = _token;
    sale = _sale;
    tokenToVToken = _tokenToVToken;
    vToken = _vToken;
  }

  // convert for msg.sender
  function convert() external payable {
    _convertFor(msg.sender);
  }

  // convert for receiver
  function convertFor(address receiver) external payable {
    _convertFor(receiver);
  }

  /**
  * @dev spit ETH input with DEX and Sale
  */
  function _convertFor(address receiver) internal {
    require(msg.value > 0, "zerro eth");
    uint256 balanceBefore = IERC20(vToken).balanceOf(receiver);

    // swap ETH
    swapETHInput(receiver, msg.value);
    // convert remains
    uint256 remains = IERC20(token).balanceOf(address(this));
    IERC20(token).approve(tokenToVToken, remains);
    IConvert(tokenToVToken).convert(receiver, remains);

    uint256 balanceAfter = IERC20(vToken).balanceOf(receiver);

    // write data
    Deposit memory deposit = Deposit(balanceBefore, balanceAfter, now);
    depositsPerUser[receiver].push(deposit);
  }


 /**
 * @dev swap ETH to token via DEX and Sale
 */
 function swapETHInput(address receiver, uint256 input) internal {
  (uint256 ethToDex, uint256 ethToSale) = calculateToSplit(input);

  // get some tokens from DEX
  if(ethToDex > 0)
    swapETHViaDEX(dexRouter, token, ethToDex);

  // get tokens from sale and reserve
 //  if(ethToSale > 0){
 //    if(reserveSplit > 0){
 //      if(IERC20(token).balanceOf(address(reserve)) >= reserveSplit){
 //
 //      }
 //    }else{
 //      swapETHViaSale(receiver, ethToSale);
 //    }
 //  }
 }

 // helper for swap ETH to vtoken
 function swapETHViaDEX(address routerDEX, address toToken, uint256 amount) internal {
   // SWAP split % of ETH input to token
   address[] memory path = new address[](2);
   path[0] = WETH;
   path[1] = toToken;

   IUniswapV2Router02(routerDEX).swapExactETHForTokens{value:amount}(
     1,
     path,
     address(this),
     block.timestamp + 1800
   );
 }

 // helper for get OHM from Sale via deposit
 function swapETHViaSale(address receiver, uint256 amount) internal {
    ISale(sale).buyFor.value(amount)(receiver);
 }


 /**
 * @dev return eth amount for dex, sale and platform
 */
 function calculateToSplitETH(uint256 ethInput)
   private
   view
   returns (
     uint256 ethToDex,
     uint256 ethToSale
   )
 {
   ethToDex = ethInput.div(100).mul(percentToDex);
   ethToSale = ethInput.div(100).mul(percentToSale);
 }

 /**
 * @dev return split % amount of input
 */
 function calculateToSplit(uint256 ethInput)
   public
   view
   returns(uint256 ethToDex, uint256 ethToSale)
 {
   (ethToDex, ethToSale) = calculateToSplitETH(ethInput);
 }

 /**
 * @dev allow owner update split % with dex and sale
 */
 function updateSplitPercent(
   uint256 _percentToDex,
   uint256 _percentToSale
 )
   external
   onlyOwner
 {
   uint256 total = _percentToDex + _percentToSale;
   require(total == 100, "Wrong total");

   percentToDex = _percentToDex;
   percentToSale = _percentToSale;
 }

 /**
 * @dev allow owner update split % with sale and reserve
 */
 function updateReserveSplit(
   uint256 _reserveSplit
 )
   external
   onlyOwner
 {
   require(reserveSplit <= 100, "Wrong percent");
   reserveSplit = _reserveSplit;
 }

 /**
 * @dev allow owner withdraw eth for case if some eth stuck or was sent accidentally
 */
 function withdraw()
   external
   onlyOwner
 {
   payable(owner()).transfer(address(this).balance);
 }

 /**
 * @dev return length of all user deposits
 */
 function totalUserDeposits(address user)
   external
   view
   returns(uint256)
 {
    Deposit[] memory deposits = depositsPerUser[user];
    return deposits.length;
 }

 fallback() external payable {}
}
