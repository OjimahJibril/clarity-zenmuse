;; ZenMuse - Mindfulness and Journaling Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-timestamp (err u103))
(define-constant err-future-timestamp (err u104))

;; Data Variables
(define-map journal-entries 
  { user: principal, entry-id: uint }
  { content: (string-utf8 1000), timestamp: uint, private: bool, last-modified: uint }
)

(define-map mindfulness-goals
  principal
  { goal: (string-utf8 100), target: uint, metric: (string-ascii 10), start-time: uint }
)

(define-map user-stats
  principal  
  { streak: uint, total-entries: uint, level: uint, last-entry-date: uint }
)

(define-data-var prompt-counter uint u0)
(define-data-var current-prompt (string-utf8 200) "What brought you peace today?")

;; Public Functions
(define-public (create-entry (content (string-utf8 1000)) (timestamp uint) (private bool))
  (let 
    (
      (user tx-sender)
      (entry-id (get-next-entry-id user))
      (current-time block-height)
    )
    (asserts! (< timestamp (+ current-time u144)) err-future-timestamp)
    (asserts! (> timestamp u0) err-invalid-timestamp)
    
    (map-set journal-entries
      { user: user, entry-id: entry-id }
      { content: content, 
        timestamp: timestamp, 
        private: private, 
        last-modified: current-time }
    )
    (update-user-stats user timestamp)
    (ok entry-id)
  )
)

(define-public (modify-entry (entry-id uint) (content (string-utf8 1000)) (private bool))
  (let (
    (entry (unwrap! (map-get? journal-entries {user: tx-sender, entry-id: entry-id}) err-not-found))
  )
    (map-set journal-entries
      { user: tx-sender, entry-id: entry-id }
      { content: content, 
        timestamp: (get timestamp entry), 
        private: private,
        last-modified: block-height }
    )
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-entry (user principal) (entry-id uint))
  (let ((entry (map-get? journal-entries {user: user, entry-id: entry-id})))
    (if (and entry (or (is-eq tx-sender user) (not (get private entry))))
      (ok entry)
      err-unauthorized
    )
  )
)

(define-read-only (get-prompt)
  (ok (var-get current-prompt))
)

(define-read-only (get-user-stats (user principal))
  (default-to
    { streak: u0, total-entries: u0, level: u1, last-entry-date: u0 }
    (map-get? user-stats user)
  )
)

;; Private Functions
(define-private (get-next-entry-id (user principal))
  (let ((stats (get-user-stats user)))
    (+ (get total-entries stats) u1)
  )
)

(define-private (update-user-stats (user principal) (timestamp uint))
  (let (
    (current-stats (get-user-stats user))
    (last-entry-date (get last-entry-date current-stats))
    (new-streak (if (is-consecutive-day? last-entry-date timestamp)
      (+ (get streak current-stats) u1)
      u1))
  )
    (map-set user-stats
      user
      {
        streak: new-streak,
        total-entries: (+ (get total-entries current-stats) u1),
        level: (calculate-level (+ (get total-entries current-stats) u1)),
        last-entry-date: timestamp
      }
    )
  )
)

(define-private (is-consecutive-day? (last-date uint) (current-date uint))
  (and 
    (> current-date last-date)
    (<= (- current-date last-date) u144)
  )
)

(define-private (calculate-level (entries uint))
  (let ((base-level (/ entries u10)))
    (if (< base-level u1) 
      u1
      base-level
    )
  )
)
