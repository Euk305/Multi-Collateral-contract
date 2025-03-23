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

;; Track vault IDs per user
(define-map user-vaults
  { owner: principal }
  { vault-ids: (list 100 uint) }
)

;; Global system parameters
(define-data-var global-debt-ceiling uint u1000000000000)  ;; Maximum total stablecoin (1 billion with 8 decimals)
(define-data-var total-debt uint u0)                       ;; Current total debt in the system
(define-data-var next-vault-id uint u1)                    ;; Auto-incrementing vault ID
(define-data-var liquidation-enabled bool true)            ;; Global liquidation circuit breaker
(define-data-var governance-token principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM) ;; Principal of governance token

;; Governance parameters
(define-map governance-parameters
  { param-name: (string-ascii 20) }
  { 
    value: uint,
    last-updated: uint 
  }
)

;; Initialize contract
(define-public (initialize (initial-oracles (list 5 principal)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    ;; Setup initial authorized oracles
    (map add-oracle initial-oracles)
    
    ;; Set initial governance parameters
    (map-set governance-parameters 
      { param-name: "surplus-buffer" } 
      { value: u500000000, last-updated: block-height }) ;; 5 BTC surplus buffer
    
    (map-set governance-parameters 
      { param-name: "debt-auction-size" } 
      { value: u50000000, last-updated: block-height })  ;; 0.5 BTC per debt auction
    
    (ok true)
  )
)

;; Helper to add an oracle
(define-private (add-oracle (oracle principal))
  (map-set authorized-oracles { oracle: oracle } { authorized: true })
)

int)
  (stability-fee uint)
  (debt-ceiling uint)
  (min-vault-debt uint)
  (adapter-name (string-ascii 20)))
  
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? collateral-types { collateral-type: collateral-type })) err-collateral-type-exists)
    
    ;; Validate parameters
    (asserts! (>= liquidation-ratio u1000000) err-invalid-parameter) ;; Minimum 100% collateralization
    (asserts! (<= liquidation-penalty u500000) err-invalid-parameter) ;; Maximum 50% penalty
    (asserts! (<= stability-fee u100000) err-invalid-parameter) ;; Maximum 10% annual rate
    
    ;; Add to collateral types map
    (map-set collateral-types
      { collateral-type: collateral-type }
      {
        token-contract: token-contract,
        liquidation-ratio: liquidation-ratio,
        liquidation-penalty: liquidation-penalty,
        stability-fee: stability-fee,
        debt-ceiling: debt-ceiling,
        enabled: true,
        min-vault-debt: min-vault-debt,
        adapter-name: adapter-name
      }
    )
    
    ;; Add to list of collateral types
    (var-set collateral-types-list (append (var-get collateral-types-list) collateral-type))
    
    (ok true)
  )
)

;; Update oracle price feed
(define-public (update-price (asset (string-ascii 10)) (price uint))
  (begin
    (asserts! (default-to false (get authorized (map-get? authorized-oracles { oracle: tx-sender }))) err-unauthorized-oracle)
    
    (map-set price-feeds
      { asset: asset }
      {
        price: price,
        decimals: u8,
        last-updated: block-height
      }
    )
    
    (ok true)
  )
)
;; Create a new vault and deposit collateral
(define-public (open-vault 
  (collateral-type (string-ascii 10)) 
  (collateral-amount uint)
  (debt-amount uint))
  
  (let (
    (vault-id (var-get next-vault-id))
    (owner tx-sender)
    (collateral-info (unwrap! (map-get? collateral-types { collateral-type: collateral-type }) err-collateral-type-not-found))
    (user-vault-list (default-to { vault-ids: (list) } (map-get? user-vaults { owner: owner })))
  )
    ;; Validate collateral type is enabled
    (asserts! (get enabled collateral-info) err-collateral-type-not-found)
    
    ;; Validate debt is above minimum
    (asserts! (>= debt-amount (get min-vault-debt collateral-info)) err-below-debt-floor)
    
    ;; Check against debt ceiling
    (asserts! (<= (+ (var-get total-debt) debt-amount) (var-get global-debt-ceiling)) err-exceeds-debt-ceiling)
    (asserts! (<= debt-amount (get debt-ceiling collateral-info)) err-exceeds-debt-ceiling)
    
    ;; Transfer collateral from user to contract
    (try! (contract-call? (get token-contract collateral-info) transfer collateral-amount owner (as-contract tx-sender)))
    
    ;; Create vault
    (map-set vaults
      { 
        owner: owner, 
        vault-id: vault-id,
        collateral-type: collateral-type
      }
      {
        collateral-amount: collateral-amount,
        debt-amount: debt-amount,
        last-interest-update: block-height
      }
    )
    
    ;; Update user's vault list
    (map-set user-vaults
      { owner: owner }
      { vault-ids: (append (get vault-ids user-vault-list) vault-id) }
    )
    
    ;; Mint stablecoin
    (try! (ft-mint? stablecoin debt-amount owner))
    
    ;; Update global state
    (var-set total-debt (+ (var-get total-debt) debt-amount))
    (var-set next-vault-id (+ vault-id u1))
    
    ;; Check if vault is properly collateralized
    (asserts! (is-vault-safe owner vault-id collateral-type) err-vault-undercollateralized)
    
    (ok vault-id)
  )
)

;; Deposit additional collateral to a vault
(define-public (deposit-collateral 
  (vault-id uint) 
  (collateral-type (string-ascii 10)) 
  (amount uint))
  
  (let (
    (owner tx-sender)
    (vault (unwrap! (map-get? vaults { owner: owner, vault-id: vault-id, collateral-type: collateral-type }) err-vault-not-found))
    (collateral-info (unwrap! (map-get? collateral-types { collateral-type: collateral-type }) err-collateral-type-not-found))
  )
    ;; Transfer collateral from user to contract
    (try! (contract-call? (get token-contract collateral-info) transfer amount owner (as-contract tx-sender)))
    
    ;; Update vault
    (map-set vaults
      { 
        owner: owner, 
        vault-id: vault-id,
        collateral-type: collateral-type
      }
      (merge vault { collateral-amount: (+ (get collateral-amount vault) amount) })
    )
    
    (ok true)
  )
)

;; Withdraw collateral from a vault
(define-public (withdraw-collateral 
  (vault-id uint) 
  (collateral-type (string-ascii 10)) 
  (amount uint))
  
  (let (
    (owner tx-sender)
    (vault (unwrap! (map-get? vaults { owner: owner, vault-id: vault-id, collateral-type: collateral-type }) err-vault-not-found))
    (collateral-info (unwrap! (map-get? collateral-types { collateral-type: collateral-type }) err-collateral-type-not-found))
    (new-collateral-amount (- (get collateral-amount vault) amount))
  )
    ;; Check if enough collateral to withdraw
    (asserts! (<= amount (get collateral-amount vault)) err-insufficient-collateral)
    
    ;; Update vault first (check safety below)
    (map-set vaults
      { 
        owner: owner, 
        vault-id: vault-id,
        collateral-type: collateral-type
      }
      (merge vault { collateral-amount: new-collateral-amount })
    )
    
    ;; Check if vault is still properly collateralized
    (asserts! (is-vault-safe owner vault-id collateral-type) err-vault-undercollateralized)
    
    ;; Transfer collateral from contract to user
    (as-contract (try! (contract-call? (get token-contract collateral-info) transfer amount (as-contract tx-sender) owner)))
    
    (ok true)
  )
)

;; Generate additional stablecoin (borrow more)
(define-public (generate-stablecoin 
  (vault-id uint) 
  (collateral-type (string-ascii 10)) 
  (amount uint))
  
  (let (
    (owner tx-sender)
    (vault (unwrap! (map-get? vaults { owner: owner, vault-id: vault-id, collateral-type: collateral-type }) err-vault-not-found))
    (collateral-info (unwrap! (map-get? collateral-types { collateral-type: collateral-type }) err-collateral-type-not-found))
    (new-debt-amount (+ (get debt-amount vault) amount))
  )
    ;; Apply accumulated stability fee
    (let ((updated-vault (accrue-stability-fee owner vault-id collateral-type)))
      
      ;; Check against debt ceiling
      (asserts! (<= (+ (var-get total-debt) amount) (var-get global-debt-ceiling)) err-exceeds-debt-ceiling)
      
      ;; Update vault
      (map-set vaults
        { 
          owner: owner, 
          vault-id: vault-id,
          collateral-type: collateral-type
        }
        (merge updated-vault { debt-amount: (+ (get debt-amount updated-vault) amount) })
      )
      
      ;; Check if vault is still properly collateralized
      (asserts! (is-vault-safe owner vault-id collateral-type) err-vault-undercollateralized)
      
      ;; Mint stablecoin
      (try! (ft-mint? stablecoin amount owner))
      
      ;; Update global state
      (var-set total-debt (+ (var-get total-debt) amount))
      
      (ok true)
    )
  )
)

;; Repay stablecoin debt
(define-public (repay-stablecoin 
  (vault-id uint) 
  (collateral-type (string-ascii 10)) 
  (amount uint))
  
  (let (
    (owner tx-sender)
    (vault (unwrap! (map-get? vaults { owner: owner, vault-id: vault-id, collateral-type: collateral-type }) err-vault-not-found))
  )
    ;; Apply accumulated stability fee first
    (let (
      (updated-vault (accrue-stability-fee owner vault-id collateral-type))
      (debt-amount (get debt-amount updated-vault))
      (repay-amount (if (> amount debt-amount) debt-amount amount))
    )
      ;; Check user has enough stablecoin
      (asserts! (<= repay-amount (ft-get-balance stablecoin owner)) err-insufficient-stablecoin-balance)
      
      ;; Burn stablecoin
      (try! (ft-burn? stablecoin repay-amount owner))
      
      ;; Update vault
      (map-set vaults
        { 
          owner: owner, 
          vault-id: vault-id,
          collateral-type: collateral-type
        }
        (merge updated-vault { debt-amount: (- debt-amount repay-amount) })
      )
      
      ;; Update global state
      (var-set total-debt (- (var-get total-debt) repay-amount))
      
      (ok true)
    )
  )
)

;; Liquidate an undercollateralized vault
(define-public (liquidate-vault 
  (owner principal) 
  (vault-id uint) 
  (collateral-type (string-ascii 10)))
  
  (let (
    (vault (unwrap! (map-get? vaults { owner: owner, vault-id: vault-id, collateral-type: collateral-type }) err-vault-not-found))
    (collateral-info (unwrap! (map-get? collateral-types { collateral-type: collateral-type }) err-collateral-type-not-found))
  )
    ;; Check global liquidation is enabled
    (asserts! (var-get liquidation-enabled) err-not-authorized)
    
    ;; Apply accumulated stability fee first
    (let ((updated-vault (accrue-stability-fee owner vault-id collateral-type)))
      
      ;; Check vault is unsafe
      (asserts! (not (is-vault-safe owner vault-id collateral-type)) err-not-authorized)
      
      ;; Calculate liquidation amounts
      (let (
        (debt-amount (get debt-amount updated-vault))
        (collateral-amount (get collateral-amount updated-vault))
        (liquidation-penalty (get liquidation-penalty collateral-info))
        (penalty-adjusted-debt (/ (* debt-amount (+ u1000000 liquidation-penalty)) u1000000))
        (price-feed (unwrap! (map-get? price-feeds { asset: collateral-type }) err-collateral-type-not-found))
        (collateral-price (get price price-feed))
        
        ;; Calculate how much collateral to seize
        (collateral-to-seize (/ (* penalty-adjusted-debt u100000000) collateral-price))
      )
        ;; Check liquidator has enough stablecoin
        (asserts! (>= (ft-get-balance stablecoin tx-sender) debt-amount) err-insufficient-stablecoin-balance)
        
        ;; Burn stablecoin from liquidator
        (try! (ft-burn? stablecoin debt-amount tx-sender))
        
        ;; Transfer collateral to liquidator
        (as-contract (try! (contract-call? 
          (get token-contract collateral-info) 
          transfer 
          (if (> collateral-to-seize collateral-amount) collateral-amount collateral-to-seize)
          (as-contract tx-sender) 
          tx-sender)))
        
        ;; Update vault (set to zero if fully liquidated)
        (map-set vaults
          { 
            owner: owner, 
            vault-id: vault-id,
            collateral-type: collateral-type
          }
          {
            collateral-amount: (if (> collateral-to-seize collateral-amount) u0 (- collateral-amount collateral-to-seize)),
            debt-amount: u0,
            last-interest-update: block-height
          }
        )
        
        ;; Update global state
        (var-set total-debt (- (var-get total-debt) debt-amount))
        
        (ok true)
      )
    )
  )
)

;; Helper function to check if a vault is safely collateralized
(define-private (is-vault-safe (owner principal) (vault-id uint) (collateral-type (string-ascii 10)))
  (let (
    (vault (unwrap! (map-get? vaults { owner: owner, vault-id: vault-id, collateral-type: collateral-type }) false))
    (collateral-info (unwrap! (map-get? collateral-types { collateral-type: collateral-type }) false))
    (price-feed (unwrap! (map-get? price-feeds { asset: collateral-type }) false))
  )
    (if (or (is-eq vault false) (is-eq collateral-info false) (is-eq price-feed false))
      false
      (let (
        (collateral-amount (get collateral-amount vault))
        (debt-amount (get debt-amount vault))
        (min-ratio (get liquidation-ratio collateral-info))
        (collateral-price (get price price-feed))
        (collateral-value-usd (* collateral-amount collateral-price))
        (required-collateral-value (* debt-amount min-ratio))
      )
        (or 
          (is-eq debt-amount u0)  ;; No debt is always safe
          (>= collateral-value-usd required-collateral-value)
        )
      )
    )
  )
)

;; Helper function to calculate and apply stability fee
(define-private (accrue-stability-fee (owner principal) (vault-id uint) (collateral-type (string-ascii 10)))
  (let (
    (vault (unwrap-panic (map-get? vaults { owner: owner, vault-id: vault-id, collateral-type: collateral-type })))
    (collateral-info (unwrap-panic (map-get? collateral-types { collateral-type: collateral-type })))
    (blocks-elapsed (- block-height (get last-interest-update vault)))
    (stability-fee (get stability-fee collateral-info))
    (debt-amount (get debt-amount vault))
    
    ;; Calculate interest: rate per block * blocks * debt
    ;; Rate per block = annual rate / (blocks per year)
    ;; Assuming 144 blocks per day = 52,560 blocks per year
    (interest-amount (/ (* (* stability-fee debt-amount) blocks-elapsed) (* u52560 u1000000)))
    
    ;; New debt with interest
    (new-debt-amount (+ debt-amount interest-amount))
    
    ;; Update global debt
    (new-total-debt (+ (var-get total-debt) interest-amount))
  )
    ;; Update global state
    (var-set total-debt new-total-debt)
    
    ;; Update and return the vault
    (let (
      (updated-vault (merge vault {
        debt-amount: new-debt-amount,
        last-interest-update: block-height
      }))
    )
      ;; Actually update in storage
      (map-set vaults
        { owner: owner, vault-id: vault-id, collateral-type: collateral-type }
        updated-vault
      )
      
      updated-vault
    )
  )
)
;; Governance functions

;; Update a collateral type parameter
(define-public (update-collateral-parameter 
  (collateral-type (string-ascii 10)) 
  (parameter (string-ascii 20)) 
  (new-value uint))
  
  (begin
    ;; Only contract owner can change parameters for now
    ;; In a full implementation, this would check governance votes
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (let ((collateral-info (unwrap! (map-get? collateral-types { collateral-type: collateral-type }) err-collateral-type-not-found)))
      (match parameter
        "liquidation-ratio" 
          (begin 
            (asserts! (>= new-value u1000000) err-invalid-parameter)
            (map-set collateral-types
              { collateral-type: collateral-type }
              (merge collateral-info { liquidation-ratio: new-value })
            )
          )
        "liquidation-penalty" 
          (begin 
            (asserts! (<= new-value u500000) err-invalid-parameter)
            (map-set collateral-types
              { collateral-type: collateral-type }
              (merge collateral-info { liquidation-penalty: new-value })
            )
          )
        "stability-fee" 
          (begin 
            (asserts! (<= new-value u100000) err-invalid-parameter)
            (map-set collateral-types
              { collateral-type: collateral-type }
              (merge collateral-info { stability-fee: new-value })
            )
          )
        "debt-ceiling" 
          (map-set collateral-types
            { collateral-type: collateral-type }
            (merge collateral-info { debt-ceiling: new-value })
          )
        "min-vault-debt" 
          (map-set collateral-types
            { collateral-type: collateral-type }
            (merge collateral-info { min-vault-debt: new-value })
          )
        (err err-invalid-parameter)
      )
      
      (ok true)
    )
  )
)

;; Update global debt ceiling
(define-public (set-global-debt-ceiling (new-ceiling uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set global-debt-ceiling new-ceiling)
    (ok true)
  )
)

;; Toggle global liquidation circuit breaker
(define-public (set-liquidation-enabled (enabled bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set liquidation-enabled enabled)
    (ok true)
  )
)

;; Toggle a specific collateral type
(define-public (set-collateral-enabled (collateral-type (string-ascii 10)) (enabled bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (let ((collateral-info (unwrap! (map-get? collateral-types { collateral-type: collateral-type }) err-collateral-type-not-found)))
      (map-set collateral-types
        { collateral-type: collateral-type }
        (merge collateral-info { enabled: enabled })
      )
      
      (ok true)
    )
  )
)

;; Read-only functions

;; Get vault information
(define-read-only (get-vault-info (owner principal) (vault-id uint) (collateral-type (string-ascii 10)))
  (map-get? vaults { owner: owner, vault-id: vault-id, collateral-type: collateral-type })
)

;; Get collateral type information
(define-read-only (get-collateral-type-info (collateral-type (string-ascii 10)))
  (map-get? collateral-types { collateral-type: collateral-type })
)

;; Get price feed information
(define-read-only (get-price-feed (asset (string-ascii 10)))
  (map-get? price-feeds { asset: asset })
)

;; Get all vaults owned by a user
(define-read-only (get-user-vault-ids (owner principal))
  (get vault-ids (default-to { vault-ids: (list) } (map-get? user-vaults { owner: owner })))
)

;; Get current collateralization ratio for a vault
(define-read-only (get-vault-collateralization (owner principal) (vault-id uint) (collateral-type (string-ascii 10)))
  (let (
    (vault (unwrap! (map-get? vaults { owner: owner, vault-id: vault-id, collateral-type: collateral-type }) none))
    (price-feed (unwrap! (map-get? price-feeds { asset: collateral-type }) none))
  )
    (match (and vault price-feed)
      true (let (
        (collateral-amount (get collateral-amount vault))
        (debt-amount (get debt-amount vault))
        (collateral-price (get price price-feed))
      )
        (if (is-eq debt-amount u0)
          (some u0)  ;; No debt means infinite collateral ratio, return 0 as special value
          (some (/ (* collateral-amount collateral-price) debt-amount))
        ))
      false none
    )
  )
)