# Push notifications (FCM)

Push sits on top of the existing in-app notifications: every notification
is still saved in the app first, and a push is sent as well when it can be.

## How it works

- **App**: after sign-in it asks for notification permission and sends its
  FCM token to `POST /api/v1/push-tokens`. The token is bound to that
  sign-in session (Sanctum token), so when the session ends (sign out, sign
  out everywhere, device reset, block, password change, account deletion)
  the token is deleted with it. On sign-out the app also deletes the token
  on the phone and clears delivered notifications (Android).
- **Tap**: the push carries `notification_id`, `type`, `user_id` and the
  target ids; the app opens the page through `NotificationNavigation` and
  marks it read. A push for a different account than the one signed in is
  ignored.
- **Server**: `PlatformNotificationService` saves the notification, then
  `PushNotificationService` queues `SendPushNotificationJob`, which sends
  through FCM HTTP v1 with the service account. The job is unique per
  notification and claims it (`notifications.push_sent_at`) before sending,
  so a notification is never pushed twice. Dead tokens are deleted;
  temporary FCM failures are retried (30 s, 2 min, 10 min).
- **Preferences**: push respects the platform switch "تفعيل الإشعارات
  الفورية", each event's switch, and the student's preference for the type
  (lessons, assignments, quizzes, grades, messages, announcements, platform
  updates) and their sound setting.

## One-time setup

### 1. APNs (needs the Apple Developer account)

1. developer.apple.com → Certificates, IDs & Profiles → Keys → **+** →
   enable *Apple Push Notifications service (APNs)* → download the `.p8`
   (it can be downloaded once). Note the **Key ID** and your **Team ID**
   (`NRG6Z6BT9K`).
2. Identifiers → `com.rshdacademy.rshd` → make sure **Push Notifications**
   is ticked, then regenerate the provisioning profiles that use it.
3. Firebase console → Project settings → Cloud Messaging → Apple app
   configuration → upload the `.p8` with the Key ID and Team ID.
4. Keep the `.p8` out of git (`*.p8` is ignored).

`ios/Runner/Runner.entitlements` has `aps-environment = development`; Xcode
switches it to production when archiving for the App Store.

### 2. Server credentials (needs the Firebase console)

1. Firebase console → Project settings → Service accounts → *Generate new
   private key*.
2. On the server only, save it as
   `storage/app/private/firebase/service-account.json` (or set
   `FIREBASE_CREDENTIALS` / `FIREBASE_CREDENTIALS_JSON` in `.env`).
   Permissions: readable by the web/queue user only (`chmod 640`).
3. Never commit it (`*service-account*.json` and the folder are ignored).

### 3. Server deploy steps

- Upload the backend changes, then `php artisan migrate` (adds
  `push_device_tokens` and `notifications.push_sent_at`), then
  `php artisan optimize:clear`.
- Run a queue worker (`QUEUE_CONNECTION=database` + `php artisan
  queue:work` under Supervisor). With `sync` the push is sent inside the
  request, which is slow for large audiences.
- Admin → Settings → Notifications → turn on **تفعيل الإشعارات الفورية**.
  The note under it says whether the server credentials were found.

## Testing on devices

Push only reaches real devices: an iPhone/iPad with the app installed from
Xcode or TestFlight (APNs key uploaded), and an Android phone with Google
Play services. Check foreground, background and closed, and the tap
destination for each type (lecture, assignment, quiz, result, message,
announcement).
