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
