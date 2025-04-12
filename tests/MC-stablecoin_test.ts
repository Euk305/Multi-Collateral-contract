;; Test file for Multi-Collateral Stablecoin with BTC Backing

;; Define mock addresses for testing
(define-constant wallet-1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
(define-constant wallet-2 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(define-constant wallet-3 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
(define-constant oracle-1 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)
(define-constant oracle-2 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB)

;; Import stablecoin contract
(use-trait ft-trait .ft-trait.ft-trait)
(impl-trait .ft-trait.ft-trait)

;; Load the stablecoin contract
(contract-call? .stablecoin-contract initialize 
  (list oracle-1 oracle-2)
)

;; Mock token contracts for collateral assets
(define-constant btc-token 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-token)
(define-constant eth-token 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.eth-token)

;; ========================================
;; Test 1: Add collateral types
;; ========================================

;; Test adding BTC as collateral
(print "Test 1.1: Adding BTC as collateral type")
(contract-call? .stablecoin-contract add-collateral-type 
  "BTC"                ;; collateral-type
  btc-token            ;; token-contract
  u1500000             ;; liquidation-ratio (150%)
  u130000              ;; liquidation-penalty (13%)
  u20000               ;; stability-fee (2%)
  u1000000000          ;; debt-ceiling (10 BTC)
  u100000              ;; min-vault-debt (0.001 BTC)
  "transfer-btc"       ;; adapter-name
)
(print (contract-call? .stablecoin-contract get-collateral-type-info "BTC"))

;; Test adding ETH as collateral
(print "Test 1.2: Adding ETH as collateral type")
(contract-call? .stablecoin-contract add-collateral-type 
  "ETH"                ;; collateral-type
  eth-token            ;; token-contract
  u1650000             ;; liquidation-ratio (165%)
  u150000              ;; liquidation-penalty (15%)
  u30000               ;; stability-fee (3%)
  u2000000000          ;; debt-ceiling (20 ETH)
  u100000              ;; min-vault-debt (0.001 ETH)
  "transfer-eth"       ;; adapter-name
)
(print (contract-call? .stablecoin-contract get-collateral-type-info "ETH"))

;; ========================================
;; Test 2: Update oracle prices
;; ========================================

;; Update BTC price (at $40,000 per BTC)
(print "Test 2.1: Updating BTC price")
(as-contract tx-sender oracle-1
  (contract-call? .stablecoin-contract update-price "BTC" u4000000000000)
)
(print (contract-call? .stablecoin-contract get-price-feed "BTC"))

;; Update ETH price (at $2,000 per ETH)
(print "Test 2.2: Updating ETH price")
(as-contract tx-sender oracle-1
  (contract-call? .stablecoin-contract update-price "ETH" u200000000000)
)
(print (contract-call? .stablecoin-contract get-price-feed "ETH"))

;; ========================================
;; Test 3: Open vaults and deposit collateral
;; ========================================

;; Wallet 1 opens a BTC vault
(print "Test 3.1: Wallet 1 opens a BTC vault")
(as-contract tx-sender wallet-1
  (contract-call? .stablecoin-contract open-vault "BTC" u10000000 u50000000)
)
(print (contract-call? .stablecoin-contract get-vault-info wallet-1 u1 "BTC"))
(print (contract-call? .stablecoin-contract get-user-vault-ids wallet-1))
;; Wallet 2 opens an ETH vault
(print "Test 3.2: Wallet 2 opens an ETH vault")
(as-contract tx-sender wallet-2
  (contract-call? .stablecoin-contract open-vault "ETH" u50000000 u60000000)
)
(print (contract-call? .stablecoin-contract get-vault-info wallet-2 u2 "ETH"))
(print (contract-call? .stablecoin-contract get-user-vault-ids wallet-2))

;; ========================================
;; Test 4: Deposit additional collateral
;; ========================================

;; Wallet 1 deposits more BTC
(print "Test 4.1: Wallet 1 deposits more BTC")
(as-contract tx-sender wallet-1
  (contract-call? .stablecoin-contract deposit-collateral u1 "BTC" u5000000)
)
(print (contract-call? .stablecoin-contract get-vault-info wallet-1 u1 "BTC"))

;; Check collateralization ratio
(print "Test 4.2: Check BTC vault collateralization ratio")
(print (contract-call? .stablecoin-contract get-vault-collateralization wallet-1 u1 "BTC"))

;; ========================================
;; Test 5: Generate additional stablecoin
;; ========================================

;; Wallet 1 generates more stablecoin
(print "Test 5.1: Wallet 1 generates more stablecoin")
(as-contract tx-sender wallet-1
  (contract-call? .stablecoin-contract generate-stablecoin u1 "BTC" u20000000)
)
(print (contract-call? .stablecoin-contract get-vault-info wallet-1 u1 "BTC"))

;; Check collateralization ratio after borrowing more
(print "Test 5.2: Check BTC vault collateralization ratio after borrowing")
(print (contract-call? .stablecoin-contract get-vault-collateralization wallet-1 u1 "BTC"))
