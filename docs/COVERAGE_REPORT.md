Compiling 132 files with Solc 0.8.26
Solc 0.8.26 finished in 4.50s
Compiler run successful with warnings:
Warning (2018): Function state mutability can be restricted to pure
  --> script/VerifyShieldFi.s.sol:13:5:
   |
13 |     function logHelp() external {
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
   --> test/AMMAndNFT.t.sol:530:5:
    |
530 |     function testFuzz_ammSwapOutputBoundedByReserve(uint96 swapAmt) public {
    |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
  --> test/FuzzSuite.t.sol:76:5:
   |
76 |     function testFuzz_convertToSharesMonotonic(uint96 a1, uint96 a2) public {
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
 --> test/MiscB.t.sol:7:5:
  |
7 |     function test_bobHasCollateral() public {
  |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
  --> test/MiscB.t.sol:11:5:
   |
11 |     function test_aliceHasCollateral() public {
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to pure
  --> test/SuiteA.t.sol:13:5:
   |
13 |     function testFuzz_premiumMathMatches(uint128 coverage, uint16 durationDays, uint16 rateBps) public {
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to pure
  --> test/SuiteA.t.sol:25:5:
   |
25 |     function testFuzz_premiumMonotonicInDuration(uint128 coverage, uint32 d1, uint32 d2) public {
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to pure
  --> test/SuiteA.t.sol:34:5:
   |
34 |     function testFuzz_premiumMonotonicInRate(uint128 coverage, uint16 r1, uint16 r2) public {
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
  --> test/SuiteA.t.sol:43:5:
   |
43 |     function test_gas_mulDivBenchmarkRecordsUsage() public {
   |     ^ (Relevant source part starts here and spans across multiple lines).

Analysing contracts...
Running tests...

Ran 5 tests for test/CoverageBoost.t.sol:MockFeedCoverageTest
[PASS] test_feedDecimals() (gas: 7921)
[PASS] test_feedDescription() (gas: 12978)
[PASS] test_feedGetRoundData() (gas: 76045)
[PASS] test_feedLatestAnswer() (gas: 73660)
[PASS] test_feedVersion() (gas: 7938)
Suite result: ok. 5 passed; 0 failed; 0 skipped; finished in 26.24ms (7.88ms CPU time)

Ran 6 tests for test/Lessons.t.sol:LessonsTest
[PASS] test_fixedLessonReentrancyGuard() (gas: 646368)
[PASS] test_fixedMintAdminCanMint() (gas: 1313962)
[PASS] test_fixedMintRequiresRole() (gas: 1271361)
[PASS] test_fixedWithdrawHappyPath() (gas: 381013)
[PASS] test_vulnerableLessonDrainsETH() (gas: 832343)
[PASS] test_vulnerableMintAnyone() (gas: 871111)
Suite result: ok. 6 passed; 0 failed; 0 skipped; finished in 34.00ms (20.58ms CPU time)

Ran 10 tests for test/CoverageBoost.t.sol:VaultBranchCoverageTest
[PASS] test_vaultInitializeZeroAdmin() (gas: 3700052)
[PASS] test_vaultMintPaused() (gas: 49987)
[PASS] test_vaultPayoutOverflowGuard() (gas: 121740)
[PASS] test_vaultPayoutRevertsWithoutRole() (gas: 122713)
[PASS] test_vaultPayoutRevertsZeroAmount() (gas: 153110)
[PASS] test_vaultPayoutRevertsZeroTo() (gas: 152954)
[PASS] test_vaultRedeemPaused() (gas: 145894)
[PASS] test_vaultUpgradeZeroImplReverts() (gas: 17467)
[PASS] test_vaultV2FeeTooHighReverts() (gas: 3724283)
[PASS] test_vaultWithdrawPaused() (gas: 145970)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 112.73ms (81.36ms CPU time)

Ran 30 tests for test/AMMAndNFT.t.sol:ShieldAMMTest
[PASS] test_ammAddLiquidityFirstProvision() (gas: 193476)
[PASS] test_ammAddLiquidityMinimumLiquidityLocked() (gas: 191029)
[PASS] test_ammAddLiquiditySecondProviderMaintainsRatio() (gas: 252534)
[PASS] test_ammAddLiquiditySlippageReverts() (gas: 199715)
[PASS] test_ammAddLiquidityZeroAddressReverts() (gas: 18571)
[PASS] test_ammAddLiquidityZeroAmountReverts() (gas: 18918)
[PASS] test_ammConstructorSameTokenReverts() (gas: 109633)
[PASS] test_ammConstructorZeroAddressReverts() (gas: 109419)
[PASS] test_ammGetAmountInRoundTrip() (gas: 12634)
[PASS] test_ammGetAmountInZeroOutputReverts() (gas: 10044)
[PASS] test_ammGetAmountInZeroReserveReverts() (gas: 10066)
[PASS] test_ammGetAmountOut03PctFee() (gas: 8607)
[PASS] test_ammGetAmountOutZeroInputReverts() (gas: 9914)
[PASS] test_ammGetAmountOutZeroReserveReverts() (gas: 9956)
[FAIL: ERC20InsufficientAllowance(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a, 0, 1000000000 [1e9])] test_ammKInvariantHoldsAfterMultipleSwaps() (gas: 213470)
[FAIL: ERC20InsufficientAllowance(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a, 0, 10000000000 [1e10])] test_ammKInvariantHoldsAfterSwap() (gas: 213442)
[PASS] test_ammLPName() (gas: 18766)
[PASS] test_ammRemoveLiquidityHappyPath() (gas: 199649)
[PASS] test_ammRemoveLiquiditySlippageReverts() (gas: 197543)
[PASS] test_ammRemoveLiquidityZeroAddressReverts() (gas: 196263)
[PASS] test_ammRemoveLiquidityZeroLpReverts() (gas: 18438)
[PASS] test_ammSwapEmitsEvent() (gas: 230454)
[PASS] test_ammSwapInvalidTokenReverts() (gas: 198185)
[FAIL: next call did not revert as expected] test_ammSwapSlippageReverts() (gas: 196376)
[PASS] test_ammSwapToken0ForToken1() (gas: 232541)
[PASS] test_ammSwapToken1ForToken0() (gas: 232512)
[FAIL: next call did not revert as expected] test_ammSwapZeroAddressReverts() (gas: 196374)
[FAIL: next call did not revert as expected] test_ammSwapZeroAmountReverts() (gas: 196418)
[PASS] test_ammSyncEmitsOnAddLiquidity() (gas: 192116)
[PASS] test_ammTokensNormalized() (gas: 7649)
Suite result: FAILED. 25 passed; 5 failed; 0 skipped; finished in 120.02ms (100.02ms CPU time)

Ran 2 tests for test/GovernanceFlow.t.sol:GovernanceFlowTest
[PASS] test_cannotProposeWithoutVotes() (gas: 32194)
[PASS] test_proposalLifecycleMintsThroughTimelock() (gas: 399823)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 25.21ms (11.99ms CPU time)

Ran 18 tests for test/ProtocolCore.t.sol:ProtocolCoreTest
[PASS] test_aliceDepositMintsShares() (gas: 117214)
[PASS] test_bobWithdrawAfterDeposit() (gas: 107932)
[PASS] test_claimPaysBuyer() (gas: 431710)
[PASS] test_collateralDecimals() (gas: 5833)
[PASS] test_doubleClaimReverts() (gas: 450288)
[PASS] test_govTokenMinterIsTimelock() (gas: 8032)
[PASS] test_insufficientLiquidityReverts() (gas: 307091)
[PASS] test_pauseBlocksDeposit() (gas: 50010)
[PASS] test_policyClaimProcessorWired() (gas: 15210)
[PASS] test_policyViewMatches() (gas: 333204)
[PASS] test_poolFactoryCreate() (gas: 676937)
[PASS] test_poolFactoryCreate2Predict() (gas: 681085)
[PASS] test_purchasePolicyRoutesFees() (gas: 337530)
[PASS] test_staleOracleReverts() (gas: 379924)
[PASS] test_treasuryOnlyTimelockWithdraws() (gas: 342795)
[PASS] test_unpauseRestoresDeposit() (gas: 122415)
[PASS] test_vaultAsset() (gas: 15244)
[PASS] test_vaultClaimRoleGranted() (gas: 17716)
Suite result: ok. 18 passed; 0 failed; 0 skipped; finished in 143.69ms (115.59ms CPU time)

Ran 17 tests for test/AMMAndNFT.t.sol:PolicyNFTTest
[PASS] test_nftConstructorZeroAdminReverts() (gas: 88102)
[PASS] test_nftConstructorZeroMinterReverts() (gas: 88124)
[PASS] test_nftMintEmitsEvent() (gas: 139390)
[PASS] test_nftMintHappyPath() (gas: 138287)
[PASS] test_nftMintMultiple() (gas: 383636)
[PASS] test_nftMintNotMinterReverts() (gas: 14507)
[PASS] test_nftMintZeroAddressReverts() (gas: 11764)
[PASS] test_nftMintsOnPolicyPurchase() (gas: 489473)
[PASS] test_nftName() (gas: 12980)
[PASS] test_nftSupportsAccessControlInterface() (gas: 6665)
[PASS] test_nftSupportsERC721Interface() (gas: 6607)
[PASS] test_nftSymbol() (gas: 13003)
[PASS] test_nftTokenByIndex() (gas: 263641)
[PASS] test_nftTokenOfOwnerByIndex() (gas: 258407)
[PASS] test_nftTokenURIContainsPolicyId() (gas: 147126)
[PASS] test_nftTokenURIRevertsForNonExistentToken() (gas: 13600)
[PASS] test_nftTransfer() (gas: 156136)
Suite result: ok. 17 passed; 0 failed; 0 skipped; finished in 146.26ms (112.15ms CPU time)

Ran 17 tests for test/CoverageBoost.t.sol:PolicyManagerBranchTest
[PASS] test_policyComputePremiumDurationTooLong() (gas: 14492)
[PASS] test_policyComputePremiumDurationTooShort() (gas: 14474)
[PASS] test_policyComputePremiumZeroCoverage() (gas: 14445)
[PASS] test_policyConsumeClaimInactivePolicy() (gas: 341150)
[PASS] test_policyConsumeClaimNotClaimable() (gas: 336863)
[PASS] test_policyConsumeClaimNotProcessor() (gas: 329927)
[PASS] test_policyDeactivateAlreadyInactive() (gas: 334847)
[PASS] test_policyInitFeeTooHigh() (gas: 2906219)
[PASS] test_policyInitZeroAsset() (gas: 2903995)
[PASS] test_policyInitZeroVault() (gas: 2903993)
[PASS] test_policyIsClaimableAfterClaim() (gas: 425932)
[PASS] test_policyIsClaimableExpired() (gas: 329894)
[PASS] test_policyIsClaimableInactive() (gas: 334710)
[PASS] test_policyPurchaseWhenPaused() (gas: 50370)
[PASS] test_policySetClaimProcessorUpdates() (gas: 26279)
[PASS] test_policySetClaimProcessorZero() (gas: 16435)
[PASS] test_policyUpgradeZeroReverts() (gas: 17490)
Suite result: ok. 17 passed; 0 failed; 0 skipped; finished in 130.98ms (98.89ms CPU time)

Ran 26 tests for test/CoverageBoost.t.sol:EdgeCaseCoverageTest
[PASS] test_claimCannotReinitialize() (gas: 27285)
[PASS] test_claimFeedAddress() (gas: 15445)
[PASS] test_claimHeartbeatStored() (gas: 12883)
[PASS] test_claimPolicyManagerAddress() (gas: 15307)
[PASS] test_claimVaultAddress() (gas: 15398)
[PASS] test_policyAnnualBpsStored() (gas: 13054)
[PASS] test_policyCannotReinitialize() (gas: 27687)
[PASS] test_policyIdSequential() (gas: 465216)
[PASS] test_policyNextIdStartsAtZero() (gas: 12903)
[PASS] test_policyPauseRevertsNonPauser() (gas: 18702)
[PASS] test_policyTreasuryFeeBpsStored() (gas: 12960)
[PASS] test_policyUnpauseRevertsNonPauser() (gas: 46083)
[PASS] test_treasuryHoldsMultipleAssets() (gas: 43486)
[PASS] test_vaultCannotReinitialize() (gas: 23126)
[PASS] test_vaultDepositZeroMintsZeroShares() (gas: 50828)
[PASS] test_vaultMaxWithdrawBounded() (gas: 122591)
[PASS] test_vaultPauseRevertsNonPauser() (gas: 18813)
[PASS] test_vaultPauseToggleEmitsEvents() (gas: 32415)
[PASS] test_vaultPayoutHappyPath() (gas: 193670)
[PASS] test_vaultSharesAssetsRoundTrip() (gas: 125077)
[PASS] test_vaultTotalPayoutsStartsZero() (gas: 12911)
[PASS] test_vaultUnpauseRevertsNonPauser() (gas: 46214)
[PASS] test_vaultV2FeeBpsBoundary() (gas: 3750151)
[PASS] test_vaultV2SetFeeBpsStores() (gas: 3744986)
[PASS] test_vaultV2VersionReturns2() (gas: 3718576)
[PASS] test_vaultVersionConstant() (gas: 10892)
Suite result: ok. 26 passed; 0 failed; 0 skipped; finished in 167.99ms (141.32ms CPU time)

Ran 13 tests for test/CoverageBoost.t.sol:ClaimProcessorBranchTest
[PASS] test_claimBadAnswerOnDynamicFeed() (gas: 3389364)
[PASS] test_claimFutureTimestampReverts() (gas: 377679)
[PASS] test_claimIncompleteRound() (gas: 3151988)
[PASS] test_claimInitZeroAdmin() (gas: 2342443)
[PASS] test_claimInitZeroFeed() (gas: 2342505)
[PASS] test_claimInitZeroHeartbeat() (gas: 2344696)
[PASS] test_claimInitZeroPolicyManager() (gas: 2342396)
[PASS] test_claimInitZeroVault() (gas: 2342527)
[PASS] test_claimPauseRequiresPauserRole() (gas: 18659)
[PASS] test_claimProcessPaused() (gas: 46674)
[PASS] test_claimUnpauseRequiresPauserRole() (gas: 46057)
[PASS] test_claimUpgradeZeroReverts() (gas: 17490)
[PASS] test_claimVersion() (gas: 10789)
Suite result: ok. 13 passed; 0 failed; 0 skipped; finished in 56.30ms (43.70ms CPU time)

Ran 5 tests for test/CoverageBoost.t.sol:GovTokenBranchTest
[PASS] test_govTokenMintNotMinterReverts() (gas: 12130)
[PASS] test_govTokenNoncesReadable() (gas: 16723)
[PASS] test_govTokenZeroMinterReverts() (gas: 92777)
[PASS] test_govTokenZeroReceiverWithSupplyReverts() (gas: 90685)
[PASS] test_govTokenZeroSupplyOk() (gas: 2930036)
Suite result: ok. 5 passed; 0 failed; 0 skipped; finished in 19.96ms (9.94ms CPU time)

Ran 12 tests for test/CoverageBoost.t.sol:TreasuryCoverageTest
[PASS] test_treasuryConstructorZeroTimelock() (gas: 58876)
[PASS] test_treasuryReceivesNative() (gas: 19921)
[PASS] test_treasuryTimelockAddress() (gas: 7941)
[PASS] test_treasuryWithdrawERC20HappyPath() (gas: 332289)
[PASS] test_treasuryWithdrawERC20RevertsNonTimelock() (gas: 20484)
[PASS] test_treasuryWithdrawERC20RevertsZeroAmount() (gas: 21717)
[PASS] test_treasuryWithdrawERC20RevertsZeroTo() (gas: 19605)
[PASS] test_treasuryWithdrawERC20RevertsZeroToken() (gas: 19560)
[PASS] test_treasuryWithdrawNativeHappyPath() (gas: 51832)
[PASS] test_treasuryWithdrawNativeRevertsNonTimelock() (gas: 17989)
[PASS] test_treasuryWithdrawNativeRevertsZeroAmount() (gas: 17631)
[PASS] test_treasuryWithdrawNativeRevertsZeroTo() (gas: 15453)
Suite result: ok. 12 passed; 0 failed; 0 skipped; finished in 33.95ms (26.60ms CPU time)

Ran 11 tests for test/FuzzSuite.t.sol:FuzzSuiteTest
[PASS] testFuzz_claimDoesNotRevertWhenFunded(int256) (runs: 256, μ: 426742, ~: 426753)
[PASS] testFuzz_convertToSharesMonotonic(uint96,uint96) (runs: 256, μ: 35247, ~: 35822)
[PASS] testFuzz_depositWithdrawRoundTrip(uint96) (runs: 256, μ: 107455, ~: 107654)
[PASS] testFuzz_maxWithdrawBound(uint96) (runs: 256, μ: 124227, ~: 124527)
[PASS] testFuzz_multipleDeposits(uint8,uint96) (runs: 256, μ: 187032, ~: 175469)
[PASS] testFuzz_oraclePriceClaimWindow(int256,bool) (runs: 256, μ: 433690, ~: 433689)
[PASS] testFuzz_pauseUnpauseIdempotent(uint8) (runs: 256, μ: 159943, ~: 137176)
[PASS] testFuzz_policyIdIncrements(uint8) (runs: 256, μ: 560460, ~: 465534)
[PASS] testFuzz_purchasePolicyPremiumPositive(uint128,uint8) (runs: 256, μ: 328928, ~: 329055)
[PASS] testFuzz_treasuryFeeNonNegative(uint128,uint8) (runs: 256, μ: 336461, ~: 336591)
[PASS] testFuzz_vaultShareNonZero(uint96) (runs: 256, μ: 115032, ~: 115332)
Suite result: ok. 11 passed; 0 failed; 0 skipped; finished in 1.94s (5.39s CPU time)

Ran 4 tests for test/ForkArbSepolia.t.sol:ForkArbSepoliaTest
[PASS] testFork_blockNumberAdvances() (gas: 6047)
[PASS] testFork_chainIdMatchesArbSepolia() (gas: 5338)
[PASS] testFork_deployMockErc20() (gas: 833178)
[PASS] testFork_readEthUsdIfConfigured() (gas: 6252)
Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 70.28s (3.27s CPU time)

Ran 26 tests for test/SuiteA.t.sol:SuiteATest
[PASS] testFuzz_premiumMathMatches(uint128,uint16,uint16) (runs: 256, μ: 7105, ~: 7105)
[PASS] testFuzz_premiumMonotonicInDuration(uint128,uint32,uint32) (runs: 256, μ: 6648, ~: 6648)
[PASS] testFuzz_premiumMonotonicInRate(uint128,uint16,uint16) (runs: 256, μ: 6137, ~: 6137)
[PASS] test_badOracleAnswerReverts() (gas: 371532)
[PASS] test_claimHeartbeat() (gas: 12861)
[PASS] test_claimIncreasesTotalPayouts() (gas: 429376)
[PASS] test_claimProcessorPauseBlocks() (gas: 46675)
[PASS] test_collateralSymbol() (gas: 12957)
[PASS] test_convertToAssetsMatches() (gas: 118783)
[PASS] test_expiredPolicyCannotClaim() (gas: 372125)
[PASS] test_gas_mulDivBenchmarkRecordsUsage() (gas: 1664)
[PASS] test_governorQuorumNumerator() (gas: 10502)
[PASS] test_maxDepositNonZero() (gas: 13482)
[PASS] test_maxMintNonZero() (gas: 13482)
[PASS] test_policyAnnualBps() (gas: 12987)
[PASS] test_policyPauseBlocksPurchase() (gas: 50371)
[PASS] test_policyTreasuryFeeBps() (gas: 12981)
[PASS] test_timelockMinDelay() (gas: 7916)
[PASS] test_treasuryReceivesERC20Premiums() (gas: 333806)
[PASS] test_triggerBelowPath() (gas: 432759)
[PASS] test_upgradeVaultToV2() (gas: 3752396)
[PASS] test_vaultName() (gas: 18036)
[PASS] test_vaultPreviewDepositPositive() (gas: 28481)
[PASS] test_vaultPreviewMintRoundTrip() (gas: 28592)
[PASS] test_vaultShareBalanceOfAlice() (gas: 115776)
[PASS] test_vaultTotalAssetsTracksDeposits() (gas: 116577)
Suite result: ok. 26 passed; 0 failed; 0 skipped; finished in 70.27s (1.40s CPU time)

Ran 30 tests for test/MiscB.t.sol:MiscBTest
[PASS] test_aliceHasCollateral() (gas: 10668)
[PASS] test_bobHasCollateral() (gas: 10646)
[PASS] test_claimDefaultAdminIsDeployer() (gas: 17728)
[PASS] test_claimProcessorFeed() (gas: 15422)
[PASS] test_claimProcessorPolicy() (gas: 15395)
[PASS] test_claimProcessorVault() (gas: 15399)
[PASS] test_govTokenName() (gas: 12959)
[PASS] test_govTokenNoncesStartsZero() (gas: 10710)
[PASS] test_govTokenSymbol() (gas: 12914)
[PASS] test_governorName() (gas: 13028)
[PASS] test_governorProposalThresholdReadable() (gas: 8083)
[PASS] test_governorQuorumAtCurrentBlock() (gas: 21742)
[PASS] test_governorStateNonexistentReverts() (gas: 12051)
[PASS] test_governorTimelockAddress() (gas: 10325)
[PASS] test_governorTokenAddress() (gas: 8363)
[PASS] test_governorVotingDelayReadable() (gas: 8037)
[PASS] test_governorVotingPeriodReadable() (gas: 8001)
[PASS] test_policyAssetIsCollateral() (gas: 15399)
[PASS] test_policyDefaultAdminIsDeployer() (gas: 17664)
[PASS] test_policyNextIdStartsZero() (gas: 12950)
[PASS] test_timelockHasGovernorProposer() (gas: 12100)
[PASS] test_timelockOpenExecutor() (gas: 9964)
[PASS] test_treasuryImmutableTimelock() (gas: 7985)
[PASS] test_vaultAssetIsCollateral() (gas: 15288)
[PASS] test_vaultDecimals() (gas: 18791)
[PASS] test_vaultDefaultAdminIsDeployer() (gas: 17661)
[PASS] test_vaultImplCodeSize() (gas: 5007)
[PASS] test_vaultPauserIsDeployer() (gas: 17677)
[PASS] test_vaultShareSymbol() (gas: 18056)
[PASS] test_vaultUpgraderIsDeployer() (gas: 17743)
Suite result: ok. 30 passed; 0 failed; 0 skipped; finished in 73.88s (146.78ms CPU time)

Ran 4 tests for test/AMMAndNFT.t.sol:ShieldAMMFuzzTest
[PASS] testFuzz_ammAddRemoveLiquidityRoundTrip(uint96) (runs: 256, μ: 97420, ~: 97420)
[PASS] testFuzz_ammGetAmountOutMonotonic(uint96,uint96) (runs: 256, μ: 15852, ~: 15852)
[FAIL: ERC20InsufficientAllowance(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a, 0, 181); counterexample: calldata=0x7d94dc6300000000000000000000000000000000000000000000000000000000000000b5 args=[181]] testFuzz_ammKNeverDecreases(uint96) (runs: 0, μ: 0, ~: 0)
[PASS] testFuzz_ammSwapOutputBoundedByReserve(uint96) (runs: 256, μ: 18306, ~: 18306)
Suite result: FAILED. 3 passed; 1 failed; 0 skipped; finished in 81.41s (83.01s CPU time)

Ran 5 tests for test/invariant/VaultInvariant.t.sol:VaultInvariantTest
[PASS] invariant_actorSharesLteTotalSupply() (runs: 256, calls: 128000, reverts: 0)

╭--------------+----------+-------+---------+----------╮
| Contract     | Selector | Calls | Reverts | Discards |
+======================================================+
| VaultHandler | deposit  | 63918 | 0       | 0        |
|--------------+----------+-------+---------+----------|
| VaultHandler | withdraw | 64082 | 0       | 0        |
╰--------------+----------+-------+---------+----------╯

[PASS] invariant_sharePriceSane() (runs: 256, calls: 128000, reverts: 0)

╭--------------+----------+-------+---------+----------╮
| Contract     | Selector | Calls | Reverts | Discards |
+======================================================+
| VaultHandler | deposit  | 63918 | 0       | 0        |
|--------------+----------+-------+---------+----------|
| VaultHandler | withdraw | 64082 | 0       | 0        |
╰--------------+----------+-------+---------+----------╯

[PASS] invariant_totalSupplyBounded() (runs: 256, calls: 128000, reverts: 0)

╭--------------+----------+-------+---------+----------╮
| Contract     | Selector | Calls | Reverts | Discards |
+======================================================+
| VaultHandler | deposit  | 63918 | 0       | 0        |
|--------------+----------+-------+---------+----------|
| VaultHandler | withdraw | 64082 | 0       | 0        |
╰--------------+----------+-------+---------+----------╯

[PASS] invariant_treasuryAccounting() (runs: 256, calls: 128000, reverts: 0)

╭--------------+----------+-------+---------+----------╮
| Contract     | Selector | Calls | Reverts | Discards |
+======================================================+
| VaultHandler | deposit  | 63918 | 0       | 0        |
|--------------+----------+-------+---------+----------|
| VaultHandler | withdraw | 64082 | 0       | 0        |
╰--------------+----------+-------+---------+----------╯

[PASS] invariant_vaultSolvent() (runs: 256, calls: 128000, reverts: 0)

╭--------------+----------+-------+---------+----------╮
| Contract     | Selector | Calls | Reverts | Discards |
+======================================================+
| VaultHandler | deposit  | 63918 | 0       | 0        |
|--------------+----------+-------+---------+----------|
| VaultHandler | withdraw | 64082 | 0       | 0        |
╰--------------+----------+-------+---------+----------╯

Suite result: ok. 5 passed; 0 failed; 0 skipped; finished in 81.38s (370.11s CPU time)

Ran 18 test suites in 81.44s (380.18s CPU time): 235 tests passed, 6 failed, 0 skipped (241 total tests)

╭----------------------------------------------------------------+------------------+------------------+----------------+-----------------╮
| File                                                           | % Lines          | % Statements     | % Branches     | % Funcs         |
+=========================================================================================================================================+
| contracts/amm/ShieldAMM.sol                                    | 93.83% (76/81)   | 89.84% (115/128) | 62.96% (17/27) | 100.00% (8/8)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/claims/ClaimProcessor.sol                            | 95.65% (44/46)   | 95.00% (57/60)   | 81.82% (9/11)  | 100.00% (8/8)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/factory/PolicyPool.sol                               | 100.00% (3/3)    | 100.00% (2/2)    | 100.00% (0/0)  | 100.00% (1/1)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/factory/PoolFactory.sol                              | 100.00% (12/12)  | 100.00% (13/13)  | 100.00% (0/0)  | 100.00% (3/3)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/governance/ShieldProtocolGovernor.sol                | 80.00% (16/20)   | 78.95% (15/19)   | 100.00% (0/0)  | 80.00% (8/10)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/lessons/fixed/FixedEthReentrancyLesson.sol           | 100.00% (8/8)    | 85.71% (6/7)     | 0.00% (0/1)    | 100.00% (2/2)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/lessons/fixed/FixedMintAccessLesson.sol              | 100.00% (5/5)    | 100.00% (3/3)    | 100.00% (0/0)  | 100.00% (2/2)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/lessons/vulnerable/VulnerableEthReentrancyLesson.sol | 88.89% (8/9)     | 87.50% (7/8)     | 33.33% (1/3)   | 100.00% (2/2)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/lessons/vulnerable/VulnerableMintAccessLesson.sol    | 100.00% (2/2)    | 100.00% (1/1)    | 100.00% (0/0)  | 100.00% (1/1)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/math/GasOptimizedMath.sol                            | 100.00% (6/6)    | 100.00% (5/5)    | 100.00% (0/0)  | 100.00% (2/2)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/mocks/MockAggregatorV3.sol                           | 100.00% (12/12)  | 100.00% (7/7)    | 100.00% (0/0)  | 100.00% (5/5)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/mocks/MockERC20.sol                                  | 100.00% (6/6)    | 100.00% (3/3)    | 100.00% (0/0)  | 100.00% (3/3)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/policy/PolicyManager.sol                             | 97.26% (71/73)   | 94.12% (80/85)   | 76.47% (13/17) | 100.00% (13/13) |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/token/PolicyNFT.sol                                  | 100.00% (16/16)  | 100.00% (18/18)  | 100.00% (3/3)  | 100.00% (4/4)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/token/ShieldGovToken.sol                             | 100.00% (13/13)  | 100.00% (13/13)  | 100.00% (4/4)  | 100.00% (4/4)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/treasury/ProtocolTreasury.sol                        | 100.00% (17/17)  | 100.00% (20/20)  | 100.00% (6/6)  | 100.00% (5/5)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/vault/InsuranceVault.sol                             | 94.12% (32/34)   | 85.29% (29/34)   | 80.00% (4/5)   | 100.00% (10/10) |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| contracts/vault/InsuranceVaultV2.sol                           | 100.00% (5/5)    | 100.00% (4/4)    | 100.00% (1/1)  | 100.00% (2/2)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| script/DeployShieldFi.s.sol                                    | 0.00% (0/59)     | 0.00% (0/72)     | 100.00% (0/0)  | 0.00% (0/7)     |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| script/VerifyShieldFi.s.sol                                    | 0.00% (0/6)      | 0.00% (0/5)      | 100.00% (0/0)  | 0.00% (0/1)     |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| test/CoverageBoost.t.sol                                       | 28.57% (2/7)     | 20.00% (1/5)     | 100.00% (0/0)  | 20.00% (1/5)    |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| test/base/ShieldFiBase.sol                                     | 100.00% (40/40)  | 100.00% (44/44)  | 100.00% (0/0)  | 100.00% (1/1)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| test/helpers/FixedReentrancyAttacker.sol                       | 100.00% (9/9)    | 100.00% (6/6)    | 100.00% (1/1)  | 100.00% (3/3)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| test/helpers/ReentrancyAttacker.sol                            | 100.00% (12/12)  | 100.00% (13/13)  | 100.00% (2/2)  | 100.00% (3/3)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| test/invariant/VaultInvariant.t.sol                            | 100.00% (24/24)  | 100.00% (26/26)  | 100.00% (2/2)  | 100.00% (3/3)   |
|----------------------------------------------------------------+------------------+------------------+----------------+-----------------|
| Total                                                          | 83.62% (439/525) | 81.20% (488/601) | 75.90% (63/83) | 87.04% (94/108) |
╰----------------------------------------------------------------+------------------+------------------+----------------+-----------------╯

Failing tests:
Encountered 1 failing test in test/AMMAndNFT.t.sol:ShieldAMMFuzzTest
[FAIL: ERC20InsufficientAllowance(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a, 0, 181); counterexample: calldata=0x7d94dc6300000000000000000000000000000000000000000000000000000000000000b5 args=[181]] testFuzz_ammKNeverDecreases(uint96) (runs: 0, μ: 0, ~: 0)

Encountered 5 failing tests in test/AMMAndNFT.t.sol:ShieldAMMTest
[FAIL: ERC20InsufficientAllowance(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a, 0, 1000000000 [1e9])] test_ammKInvariantHoldsAfterMultipleSwaps() (gas: 213470)
[FAIL: ERC20InsufficientAllowance(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a, 0, 10000000000 [1e10])] test_ammKInvariantHoldsAfterSwap() (gas: 213442)
[FAIL: next call did not revert as expected] test_ammSwapSlippageReverts() (gas: 196376)
[FAIL: next call did not revert as expected] test_ammSwapZeroAddressReverts() (gas: 196374)
[FAIL: next call did not revert as expected] test_ammSwapZeroAmountReverts() (gas: 196418)

Encountered a total of 6 failing tests, 235 tests succeeded

Tip: Run `forge test --rerun` to retry only the 6 failed tests

Fuzz seed: 0x100fa69a5f1710a95cdef94889b02845d640b19adf0e357b8d4be7d49ee70e6 (use `--fuzz-seed` to reproduce)
