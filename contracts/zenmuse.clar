;; ZenMuse - Mindfulness and Journaling Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-map journal-entries 
  { user: principal, entry-id: uint }
  { content: (string-utf8 1000), timestamp: uint, private: bool }
)

(define-map mindfulness-goals
  principal
  { goal: (string-utf8 100), target: uint, metric: (string-ascii 10), start-time: uint }
)

(define-map user-stats
  principal  
  { streak: uint, total-entries: uint, level: uint }
)

(define-data-var prompt-counter uint u0)
(define-data-var current-prompt (string-utf8 200) "What brought you peace today?")

;; Public Functions
(define-public (create-entry (content (string-utf8 1000)) (timestamp uint) (private bool))
  (let 
    (
      (user tx-sender)
      (entry-id (get-next-entry-id user))
    )
    (map-set journal-entries
      { user: user, entry-id: entry-id }
      { content: content, timestamp: timestamp, private: private }
    )
    (update-user-stats user)
    (ok entry-id)
  )
)

(define-public (set-goal (goal (string-utf8 100)) (target uint) (metric (string-ascii 10)))
  (begin
    (map-set mindfulness-goals
      tx-sender
      { 
        goal: goal,
        target: target,
        metric: metric,
        start-time: block-height
      }
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
    { streak: u0, total-entries: u0, level: u1 }
    (map-get? user-stats user)
  )
)

;; Private Functions
(define-private (get-next-entry-id (user principal))
  (let ((stats (get-user-stats user)))
    (+ (get total-entries stats) u1)
  )
)

(define-private (update-user-stats (user principal))
  (let ((current-stats (get-user-stats user)))
    (map-set user-stats
      user
      {
        streak: (+ (get streak current-stats) u1),
        total-entries: (+ (get total-entries current-stats) u1),
        level: (calculate-level (+ (get total-entries current-stats) u1))
      }
    )
  )
)

(define-private (calculate-level (entries uint))
  (/ entries u10)
)
