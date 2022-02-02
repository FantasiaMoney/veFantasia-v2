import { BN, fromWei, toWei } from 'web3-utils'
import ether from './helpers/ether'
import EVMRevert from './helpers/EVMRevert'
import { duration } from './helpers/duration'
import { PairHash } from '../config'


const BigNumber = BN
const timeMachine = require('ganache-time-traveler')

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()



// real contracts
const UniswapV2Factory = artifacts.require('./UniswapV2Factory.sol')
const UniswapV2Router = artifacts.require('./UniswapV2Router02.sol')
const UniswapV2Pair = artifacts.require('./UniswapV2Pair.sol')
const WETH = artifacts.require('./WETH9.sol')
const TOKEN = artifacts.require('./Token.sol')
const VTOKEN = artifacts.require('./VToken.sol')
const Minter = artifacts.require('./Minter.sol')
const VTokenToToken = artifacts.require('./VTokenToToken.sol')
const TokenToVToken = artifacts.require('./TokenToVToken.sol')
const LDManager = artifacts.require('./LDManager.sol')
const VTokenSale = artifacts.require('./VTokenSale.sol')
const Fetch = artifacts.require('./Fetch.sol')


let uniFactory,
    uniRouter,
    weth,
    token,
    vToken,
    pair,
    tokenMinter,
    vTokenMinter,
    vTokenToToken,
    tokenToVToken,
    ldManager,
    vTokenSale,
    fetch


contract('Fetch', function([userOne, userTwo, userThree]) {

  async function deployContracts(){
    // deploy contracts
    weth = await WETH.new()

    uniFactory = await UniswapV2Factory.new(userOne)
    uniRouter = await UniswapV2Router.new(uniFactory.address, weth.address)

    token = await TOKEN.new("DAO", "DAO",toWei(String(1000)))

    // add token liquidity
    await token.approve(uniRouter.address, toWei(String(500)))
    await uniRouter.addLiquidityETH(
      token.address,
      toWei(String(500)),
      1,
      1,
      userOne,
      "1111111111111111111111"
    , { from:userOne, value:toWei(String(500)) })

    pair = await UniswapV2Pair.at(await uniFactory.allPairs(0))

    // depoy vToken
    vToken = await VTOKEN.new("vDAO", "vDAO")

    // deploy minters
    vTokenMinter = await Minter.new(vToken.address)
    tokenMinter = await Minter.new(token.address)

    // transfer tokens ownership to minters
    token.transferOwnership(tokenMinter.address)
    vToken.transferOwnership(vTokenMinter.address)

    // deploy vToken to token converter
    vTokenToToken = await VTokenToToken.new(tokenMinter.address, vToken.address)

    // deploy token to vToken converter
    tokenToVToken = await TokenToVToken.new(token.address, vTokenMinter.address)

    // deploy LD manager
    ldManager = await LDManager.new(uniRouter.address, token.address, tokenMinter.address)

    // deploy V sale
    vTokenSale = await VTokenSale.new(
      token.address,
      vTokenMinter.address,
      userOne, // dev BENEFICIARY
      userOne, // charity BENEFICIARY
      ldManager.address,
      uniRouter.address
    )

    // update permitions for vTokenMinter
    await vTokenMinter.updatePermittion(vTokenSale.address, true)
    await vTokenMinter.updatePermittion(tokenToVToken.address, true)

    // update permitions for tokenMinter
    await tokenMinter.updatePermittion(ldManager.address, true)
    await tokenMinter.updatePermittion(vTokenToToken.address, true)

    fetch = await Fetch.new(
      weth.address,
      uniRouter.address,
      token.address,
      vTokenSale.address,
      tokenToVToken.address,
      vToken.address
    )
  }

  beforeEach(async function() {
    await deployContracts()
  })

  describe('Fetch', function() {
    it('Convert input to vToken', async function() {
      console.log(
        "Purchase length before ",
        Number(await fetch.totalUserPurchases(userTwo))
      )

      // user two not hold any vtoken before deposit
      assert.equal(Number(await vToken.balanceOf(userTwo)), 0)
      // deposit
      await fetch.convert({ from:userTwo, value:toWei(String(1)) })
      // user two get vtoken
      assert.notEqual(Number(await vToken.balanceOf(userTwo)), 0)
      // fetch send all pool
      assert.equal(Number(await pair.balanceOf(fetch.address)), 0)
      // fetch send all vTokens
      assert.equal(Number(await vToken.balanceOf(fetch.address)), 0)
      // fetch send all ETH remains
      assert.equal(Number(await web3.eth.getBalance(fetch.address)), 0)
      // fetch send all WETH remains
      assert.equal(Number(await weth.balanceOf(fetch.address)), 0)
      // fetch send all tokens
      assert.equal(Number(await token.balanceOf(fetch.address)), 0)

      console.log(
        "Purchase length after ",
        Number(await fetch.totalUserPurchases(userTwo))
      )
    })
  })
  //END
})
