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
const Reserve = artifacts.require('./Reserve.sol')


let uniFactory,
    uniRouter,
    weth,
    token,
    vToken,
    pair,
    tokenMinter,
    vTokenMinter,
    reserve



contract('Reserve-test', function([userOne, userTwo, userThree]) {

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

    reserve = await Reserve.new(token.address, uniRouter.address, weth.address)
  }

  beforeEach(async function() {
    await deployContracts()
  })

  describe('Reserve deposit', function() {
    const toDeposit = toWei("1")

    it('Can not be deposited without approve', async function() {
      await reserve.deposit(toDeposit)
      .should.be.rejectedWith(EVMRevert)
    })

    it('Can be deposited', async function() {
      assert.equal(0, await reserve.depositOf(userOne))
      await token.approve(reserve.address, toDeposit)
      await reserve.deposit(toDeposit)
      assert.equal(toDeposit, await reserve.depositOf(userOne))
    })
  })

  describe('Reserve withdraw', function() {
    const toDeposit = toWei("1")

    it('Can not withdraw without deposit', async function() {
      await reserve.withdraw(toDeposit)
      .should.be.rejectedWith(EVMRevert)
    })

    it('Can withdraw after deposit', async function() {
      await token.approve(reserve.address, toDeposit)
      await reserve.deposit(toDeposit)

      assert.equal(toDeposit, await reserve.depositOf(userOne))
      assert.equal(toDeposit, await token.balanceOf(reserve.address))

      await reserve.withdraw(toDeposit)
      assert.equal(0, await reserve.depositOf(userOne))
      assert.equal(0, await token.balanceOf(reserve.address))
    })
  })

  describe('Reserve convert', function() {
    const toDeposit = toWei("1")

    it('Can not be converted if not enough eth', async function() {
      await token.approve(reserve.address, toDeposit)
      await reserve.deposit(toDeposit)
      await reserve.convert(toDeposit)
      .should.be.rejectedWith(EVMRevert)
    })

    it('Can not be converted if enough eth but not enough deposit', async function() {
      const requireETH = await reserve.currentRate(toDeposit)
      await reserve.sendTransaction({
        value: requireETH,
        from:userOne
      })
      await reserve.convert(toDeposit)
      .should.be.rejectedWith(EVMRevert)
    })

    it('Can be converted if enough eth and enough deposit', async function() {
      await token.approve(reserve.address, toDeposit)
      await reserve.deposit(toDeposit)

      const requireETH = await reserve.currentRate(toDeposit)
      await reserve.sendTransaction({
        value: requireETH,
        from:userOne
      })
      await reserve.convert(toDeposit)
    })
  })

  //END
})
