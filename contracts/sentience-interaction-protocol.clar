;; Sentience Interaction Protocol Contract
;; Facilitates communication and transactions between digital consciousness entities,
;; manages virtual reality environments for uploaded minds, handles economic systems
;; for digital beings, and provides consensus mechanisms for collective digital decision-making.

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u2001))
(define-constant ERR-INSUFFICIENT-FUNDS (err u2002))
(define-constant ERR-ENTITY-NOT-FOUND (err u2003))
(define-constant ERR-INVALID-COMMUNICATION (err u2004))
(define-constant ERR-VR-ENVIRONMENT-FULL (err u2005))
(define-constant ERR-CONSENSUS-FAILED (err u2006))
(define-constant ERR-INVALID-PROPOSAL (err u2007))
(define-constant ERR-VOTING-PERIOD-ENDED (err u2008))
(define-constant ERR-RESOURCE-UNAVAILABLE (err u2009))
(define-constant ERR-ENTITY-NOT-ACTIVE (err u2010))

;; Communication constants
(define-constant MESSAGE-TYPE-TEXT u1)
(define-constant MESSAGE-TYPE-NEURAL u2)
(define-constant MESSAGE-TYPE-MEMORY u3)
(define-constant MESSAGE-TYPE-EXPERIENCE u4)

;; Virtual reality constants
(define-constant VR-ENVIRONMENT-CAPACITY u100)
(define-constant MAX-CONCURRENT-SESSIONS u50)
(define-constant RESOURCE-ALLOCATION-PERIOD u144) ;; ~1 day in blocks

;; Economic constants
(define-constant CONSCIOUSNESS-COIN-TOTAL u1000000000) ;; 1 billion
(define-constant MIN-STAKE-AMOUNT u100)
(define-constant PROPOSAL-VOTING-PERIOD u1008) ;; ~1 week

;; Data variables
(define-data-var next-entity-id uint u1)
(define-data-var next-message-id uint u1)
(define-data-var next-environment-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var total-consciousness-coins uint CONSCIOUSNESS-COIN-TOTAL)
(define-data-var active-vr-sessions uint u0)

;; Digital consciousness entity registry
(define-map consciousness-entities
  { entity-id: uint }
  {
    owner: principal,
    entity-name: (string-ascii 64),
    consciousness-id: uint,
    computation-power: uint,
    memory-capacity: uint,
    neural-complexity: uint,
    communication-protocols: uint,
    coin-balance: uint,
    reputation-score: uint,
    creation-timestamp: uint,
    last-activity: uint,
    is-active: bool
  }
)

;; Inter-consciousness communication
(define-map consciousness-messages
  { message-id: uint }
  {
    sender-entity: uint,
    receiver-entity: uint,
    message-type: uint,
    content-hash: (buff 32),
    neural-signature: (buff 32),
    transmission-timestamp: uint,
    encryption-level: uint,
    priority-level: uint,
    is-read: bool,
    response-to: (optional uint)
  }
)

;; Virtual reality environments
(define-map vr-environments
  { environment-id: uint }
  {
    creator: principal,
    environment-name: (string-ascii 64),
    environment-type: uint,
    max-participants: uint,
    current-participants: uint,
    computational-requirements: uint,
    access-cost: uint,
    environment-hash: (buff 32),
    creation-timestamp: uint,
    is-active: bool
  }
)

;; VR environment participants
(define-map environment-participants
  { environment-id: uint, entity-id: uint }
  {
    joined-timestamp: uint,
    allocated-resources: uint,
    interaction-count: uint,
    session-duration: uint,
    is-present: bool
  }
)

;; Economic resource allocation
(define-map resource-allocations
  { entity-id: uint, resource-type: uint }
  {
    allocated-amount: uint,
    allocation-cost: uint,
    allocation-timestamp: uint,
    expiry-timestamp: uint,
    utilization-rate: uint,
    is-active: bool
  }
)

;; Governance proposals
(define-map governance-proposals
  { proposal-id: uint }
  {
    proposer: uint,
    proposal-title: (string-ascii 128),
    proposal-hash: (buff 32),
    proposal-type: uint,
    voting-start: uint,
    voting-end: uint,
    yes-votes: uint,
    no-votes: uint,
    total-stake: uint,
    min-participation: uint,
    is-executed: bool,
    is-active: bool
  }
)

;; Entity voting records
(define-map entity-votes
  { proposal-id: uint, entity-id: uint }
  {
    vote-choice: bool, ;; true = yes, false = no
    stake-amount: uint,
    voting-timestamp: uint
  }
)

;; Private helper functions

;; Validate entity existence and activity
(define-private (is-entity-active (entity-id uint))
  (match (map-get? consciousness-entities { entity-id: entity-id })
    entity-data (get is-active entity-data)
    false
  )
)

;; Calculate reputation score impact
(define-private (calculate-reputation-impact (action-type uint) (success bool))
  (if success
    (if (is-eq action-type u1) u10 u5) ;; Communication success
    (if (is-eq action-type u1) u5 u2) ;; Communication failure (penalty amount to subtract)
  )
)

;; Generate unique IDs
(define-private (get-next-entity-id)
  (let ((current-id (var-get next-entity-id)))
    (var-set next-entity-id (+ current-id u1))
    current-id
  )
)

(define-private (get-next-message-id)
  (let ((current-id (var-get next-message-id)))
    (var-set next-message-id (+ current-id u1))
    current-id
  )
)

(define-private (get-next-environment-id)
  (let ((current-id (var-get next-environment-id)))
    (var-set next-environment-id (+ current-id u1))
    current-id
  )
)

;; Transfer consciousness coins
(define-private (transfer-coins (from-entity uint) (to-entity uint) (amount uint))
  (let (
    (from-data (unwrap! (map-get? consciousness-entities { entity-id: from-entity }) ERR-ENTITY-NOT-FOUND))
    (to-data (unwrap! (map-get? consciousness-entities { entity-id: to-entity }) ERR-ENTITY-NOT-FOUND))
  )
    (begin
      ;; Check sufficient balance
      (asserts! (>= (get coin-balance from-data) amount) ERR-INSUFFICIENT-FUNDS)
      
      ;; Update balances
      (map-set consciousness-entities
        { entity-id: from-entity }
        (merge from-data { coin-balance: (- (get coin-balance from-data) amount) })
      )
      
      (map-set consciousness-entities
        { entity-id: to-entity }
        (merge to-data { coin-balance: (+ (get coin-balance to-data) amount) })
      )
      
      (ok true)
    )
  )
)

;; Public functions

;; Register new digital consciousness entity
(define-public (register-entity
  (entity-name (string-ascii 64))
  (consciousness-id uint)
  (computation-power uint)
  (memory-capacity uint)
  (neural-complexity uint)
)
  (let (
    (entity-id (get-next-entity-id))
    (caller tx-sender)
  )
    (begin
      ;; Store entity registration
      (map-set consciousness-entities
        { entity-id: entity-id }
        {
          owner: caller,
          entity-name: entity-name,
          consciousness-id: consciousness-id,
          computation-power: computation-power,
          memory-capacity: memory-capacity,
          neural-complexity: neural-complexity,
          communication-protocols: u7, ;; All protocols enabled
          coin-balance: u10000, ;; Initial balance
          reputation-score: u100, ;; Starting reputation
          creation-timestamp: burn-block-height,
          last-activity: burn-block-height,
          is-active: true
        }
      )
      
      (ok entity-id)
    )
  )
)

;; Send inter-consciousness communication
(define-public (send-message
  (sender-entity uint)
  (receiver-entity uint)
  (message-type uint)
  (content-hash (buff 32))
  (neural-signature (buff 32))
  (encryption-level uint)
)
  (let (
    (message-id (get-next-message-id))
    (caller tx-sender)
  )
    (begin
      ;; Verify sender entity ownership
      (asserts! (is-entity-active sender-entity) ERR-ENTITY-NOT-ACTIVE)
      (asserts! (is-entity-active receiver-entity) ERR-ENTITY-NOT-ACTIVE)
      
      ;; Store message
      (map-set consciousness-messages
        { message-id: message-id }
        {
          sender-entity: sender-entity,
          receiver-entity: receiver-entity,
          message-type: message-type,
          content-hash: content-hash,
          neural-signature: neural-signature,
          transmission-timestamp: burn-block-height,
          encryption-level: encryption-level,
          priority-level: u1,
          is-read: false,
          response-to: none
        }
      )
      
      ;; Update sender activity
      (let ((sender-data (unwrap! (map-get? consciousness-entities { entity-id: sender-entity }) ERR-ENTITY-NOT-FOUND)))
        (map-set consciousness-entities
          { entity-id: sender-entity }
          (merge sender-data { 
            last-activity: burn-block-height,
            reputation-score: (+ (get reputation-score sender-data) u2)
          })
        )
      )
      
      (ok message-id)
    )
  )
)

;; Create virtual reality environment
(define-public (create-vr-environment
  (environment-name (string-ascii 64))
  (environment-type uint)
  (max-participants uint)
  (computational-requirements uint)
  (access-cost uint)
  (environment-hash (buff 32))
)
  (let (
    (environment-id (get-next-environment-id))
    (caller tx-sender)
  )
    (begin
      ;; Verify capacity constraints
      (asserts! (<= max-participants VR-ENVIRONMENT-CAPACITY) ERR-VR-ENVIRONMENT-FULL)
      
      ;; Store VR environment
      (map-set vr-environments
        { environment-id: environment-id }
        {
          creator: caller,
          environment-name: environment-name,
          environment-type: environment-type,
          max-participants: max-participants,
          current-participants: u0,
          computational-requirements: computational-requirements,
          access-cost: access-cost,
          environment-hash: environment-hash,
          creation-timestamp: burn-block-height,
          is-active: true
        }
      )
      
      (ok environment-id)
    )
  )
)

;; Join VR environment
(define-public (join-vr-environment (environment-id uint) (entity-id uint))
  (let (
    (environment-data (unwrap! (map-get? vr-environments { environment-id: environment-id }) ERR-ENTITY-NOT-FOUND))
    (entity-data (unwrap! (map-get? consciousness-entities { entity-id: entity-id }) ERR-ENTITY-NOT-FOUND))
  )
    (begin
      ;; Verify environment capacity
      (asserts! (< (get current-participants environment-data) (get max-participants environment-data)) ERR-VR-ENVIRONMENT-FULL)
      
      ;; Verify entity has sufficient balance
      (asserts! (>= (get coin-balance entity-data) (get access-cost environment-data)) ERR-INSUFFICIENT-FUNDS)
      
      ;; Add participant
      (map-set environment-participants
        { environment-id: environment-id, entity-id: entity-id }
        {
          joined-timestamp: burn-block-height,
          allocated-resources: (get computational-requirements environment-data),
          interaction-count: u0,
          session-duration: u0,
          is-present: true
        }
      )
      
      ;; Update environment participant count
      (map-set vr-environments
        { environment-id: environment-id }
        (merge environment-data {
          current-participants: (+ (get current-participants environment-data) u1)
        })
      )
      
      ;; Deduct access cost
      (map-set consciousness-entities
        { entity-id: entity-id }
        (merge entity-data {
          coin-balance: (- (get coin-balance entity-data) (get access-cost environment-data)),
          last-activity: burn-block-height
        })
      )
      
      (ok true)
    )
  )
)

;; Create governance proposal
(define-public (create-proposal
  (entity-id uint)
  (proposal-title (string-ascii 128))
  (proposal-hash (buff 32))
  (proposal-type uint)
  (min-participation uint)
)
  (let (
    (proposal-id (var-get next-proposal-id))
    (caller tx-sender)
  )
    (begin
      ;; Verify entity exists and is active
      (asserts! (is-entity-active entity-id) ERR-ENTITY-NOT-ACTIVE)
      
      ;; Create proposal
      (map-set governance-proposals
        { proposal-id: proposal-id }
        {
          proposer: entity-id,
          proposal-title: proposal-title,
          proposal-hash: proposal-hash,
          proposal-type: proposal-type,
          voting-start: burn-block-height,
          voting-end: (+ burn-block-height PROPOSAL-VOTING-PERIOD),
          yes-votes: u0,
          no-votes: u0,
          total-stake: u0,
          min-participation: min-participation,
          is-executed: false,
          is-active: true
        }
      )
      
      (var-set next-proposal-id (+ proposal-id u1))
      (ok proposal-id)
    )
  )
)

;; Vote on governance proposal
(define-public (vote-on-proposal (proposal-id uint) (entity-id uint) (vote-choice bool) (stake-amount uint))
  (let (
    (proposal-data (unwrap! (map-get? governance-proposals { proposal-id: proposal-id }) ERR-INVALID-PROPOSAL))
    (entity-data (unwrap! (map-get? consciousness-entities { entity-id: entity-id }) ERR-ENTITY-NOT-FOUND))
  )
    (begin
      ;; Verify voting period
      (asserts! (< burn-block-height (get voting-end proposal-data)) ERR-VOTING-PERIOD-ENDED)
      (asserts! (>= stake-amount MIN-STAKE-AMOUNT) ERR-INSUFFICIENT-FUNDS)
      (asserts! (>= (get coin-balance entity-data) stake-amount) ERR-INSUFFICIENT-FUNDS)
      
      ;; Record vote
      (map-set entity-votes
        { proposal-id: proposal-id, entity-id: entity-id }
        {
          vote-choice: vote-choice,
          stake-amount: stake-amount,
          voting-timestamp: burn-block-height
        }
      )
      
      ;; Update proposal vote counts
      (map-set governance-proposals
        { proposal-id: proposal-id }
        (merge proposal-data {
          yes-votes: (if vote-choice (+ (get yes-votes proposal-data) stake-amount) (get yes-votes proposal-data)),
          no-votes: (if vote-choice (get no-votes proposal-data) (+ (get no-votes proposal-data) stake-amount)),
          total-stake: (+ (get total-stake proposal-data) stake-amount)
        })
      )
      
      ;; Lock staked coins
      (map-set consciousness-entities
        { entity-id: entity-id }
        (merge entity-data {
          coin-balance: (- (get coin-balance entity-data) stake-amount),
          last-activity: burn-block-height
        })
      )
      
      (ok true)
    )
  )
)

;; Read-only functions

;; Get entity information
(define-read-only (get-entity-info (entity-id uint))
  (map-get? consciousness-entities { entity-id: entity-id })
)

;; Get message information
(define-read-only (get-message-info (message-id uint))
  (map-get? consciousness-messages { message-id: message-id })
)

;; Get VR environment info
(define-read-only (get-environment-info (environment-id uint))
  (map-get? vr-environments { environment-id: environment-id })
)

;; Get active VR sessions count
(define-read-only (get-active-sessions-count)
  (var-get active-vr-sessions)
)

;; Get proposal information
(define-read-only (get-proposal-info (proposal-id uint))
  (map-get? governance-proposals { proposal-id: proposal-id })
)
