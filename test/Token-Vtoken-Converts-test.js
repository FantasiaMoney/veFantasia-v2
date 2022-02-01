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

const ETH_TOKEN_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'

const url = "https://gateway.pinata.cloud/ipfs/QmNVZdcfwaadBzKkDFfGXtqNdKwEbMsQY5xZJxfSxNcK2i/1/"

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
    vTokenSale


contract('Token-Vtoken-Converts-test', function([userOne, userTwo, userThree]) {

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
      userOne, // BENEFICIARY
      uniRouter.address
    )

    // update permitions for vTokenMinter
    await vTokenMinter.updatePermittion(vTokenSale.address, true)
    await vTokenMinter.updatePermittion(tokenToVToken.address, true)

    // update permitions for tokenMinter
    await tokenMinter.updatePermittion(ldManager.address, true)
    await tokenMinter.updatePermittion(vTokenToToken.address, true)
  }

  beforeEach(async function() {
    await deployContracts()
  })

  describe('INIT', function() {
    it('token should be added in LD DEX', async function() {
      assert.equal(await pair.totalSupply(), toWei(String(500)))
    })
  })

  describe('token', function() {
    it('can be converter from vToken to token and supplies changed', async function() {
      const tokenSupplyBefore = await token.totalSupply()
      // buy some vtoken
      await vTokenSale.buyFor(userOne, { from:userOne, value:toWei("1") })
      const vTokenRecieved = await vToken.balanceOf(userOne)
      assert.isTrue(Number(vTokenRecieved) > 0)

      const vTokenSupplyBefore = await vToken.totalSupply()

      await vToken.approveBurn(vTokenToToken.address, vTokenRecieved)
      await vTokenToToken.convert(userOne, vTokenRecieved)

      assert.isTrue(Number(tokenSupplyBefore) < Number(await token.totalSupply()))
      assert.isTrue(Number(vTokenSupplyBefore) > Number(await vToken.totalSupply()))
    })

    it('LD manager mint token and LD ', async function() {
      const tokenSupplyBefore = await token.totalSupply()
      const totalLDBefore = await pair.totalSupply()

      await ldManager.addLiquidity({ from:userOne, value:toWei("10") })

      assert.isTrue(Number(tokenSupplyBefore) < Number(await token.totalSupply()))
      assert.isTrue(Number(totalLDBefore) < Number(await pair.totalSupply()))
    })
  })

  describe('vToken', function() {
    it('can be converted from token to vToken and supplies changed', async function() {
      const tokenSupplyBefore = await token.totalSupply()
      const vTokenSupplyBefore = await vToken.totalSupply()

      assert.equal(await vToken.balanceOf(userOne), 0)
      await token.approve(tokenToVToken.address, toWei("1"))
      await tokenToVToken.convert(userOne, toWei("1"))
      assert.equal(await vToken.balanceOf(userOne), toWei("1"))

      assert.isTrue(Number(tokenSupplyBefore) > Number(await token.totalSupply()))
      assert.isTrue(Number(vTokenSupplyBefore) < Number(await vToken.totalSupply()))
    })

    it('can buy vToken via sale and vToken supply inreased', async function() {
      const vTokenSupplyBefore = await vToken.totalSupply()
      const rate = await uniRouter.getAmountsOut(
        toWei("1"),
        [weth.address, token.address]
      )

      const shouldRecive = rate[1]

      assert.equal(await vToken.balanceOf(userOne), 0)
      await vTokenSale.buyFor(userOne, { from:userOne, value:toWei("1") })

      assert.equal(
        Number(await vToken.balanceOf(userOne)),
        Number(shouldRecive)
      )

      assert.isTrue(Number(vTokenSupplyBefore) < Number(await vToken.totalSupply()))
    })
  })


  //END
})
