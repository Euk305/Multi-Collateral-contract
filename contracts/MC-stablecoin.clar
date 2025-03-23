;; Multi-Collateral Stablecoin with BTC Backing
;; A stablecoin system that uses multiple collateral types with Bitcoin as primary backing

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-insufficient-collateral (err u102))
(define-constant err-vault-not-found (err u103))
(define-constant err-vault-undercollateralized (err u104))
(define-constant err-exceeds-debt-ceiling (err u105))
(define-constant err-below-debt-floor (err u106))
(define-constant err-collateral-type-exists (err u107))
(define-constant err-collateral-type-not-found (err u108))
(define-constant err-invalid-parameter (err u109))
(define-constant err-unauthorized-oracle (err u110))
(define-constant err-stablecoin-transfer-failed (err u111))
(define-constant err-insufficient-stablecoin-balance (err u112))
(define-constant err-vault-already-liquidated (err u113))

;; Token definitions
(define-fungible-token stablecoin)

;; Oracle price data - updated by trusted oracles
(define-map price-feeds
  { asset: (string-ascii 10) }
  { 
    price: uint,            ;; Price in USD * 10^8 (e.g., $1.00 = 100000000)
    decimals: uint,         ;; Decimal precision of the price feed
    last-updated: uint      ;; Block height of last update
  }
)

;; Authorized oracle principals
(define-map authorized-oracles
  { oracle: principal }
  { authorized: bool }
)

;; Collateral types and their parameters
(define-map collateral-types
  { collateral-type: (string-ascii 10) }
  {
    token-contract: principal,    ;; Contract that handles this token
    liquidation-ratio: uint,      ;; Minimum collateralization ratio (e.g., 150% = 1500000)
    liquidation-penalty: uint,    ;; Penalty applied during liquidation (e.g., 13% = 130000)
    stability-fee: uint,          ;; Annual interest rate (e.g., 2% = 20000)
    debt-ceiling: uint,           ;; Maximum stablecoin that can be minted with this collateral
    enabled: bool,                ;; Whether this collateral type is active
    min-vault-debt: uint,         ;; Minimum amount of debt per vault
    adapter-name: (string-ascii 20) ;; Function name to call for transfers
  }
)

;; List of all supported collateral types
(define-data-var collateral-types-list (list 10 (string-ascii 10)) (list))

;; Vaults - where users lock collateral and mint stablecoin
(define-map vaults
  { 
    owner: principal, 
    vault-id: uint,
    collateral-type: (string-ascii 10)
  }
  {
    collateral-amount: uint,   ;; Amount of collateral locked
    debt-amount: uint,         ;; Amount of stablecoin debt
    last-interest-update: uint ;; Block height of last interest accrual
  }
)