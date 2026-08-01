# RSHD API Contract v1

> **Base URL:** `/api/v1`  
> **Auth:** Laravel Sanctum Bearer Token  
> **Content-Type:** `application/json`  
> **Accept:** `application/json`

---

## Response Envelope (Global)

### Success (single resource / action)

```json
{
  "success": true,
  "message": "تمت العملية بنجاح",
  "data": {}
}
```

> `message` اختياري في بعض GET requests.

### Success (list)

```json
{
  "success": true,
  "data": [],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 0
  }
}
```

> حالياً لا يوجد pagination فعلي؛ `meta` يعكس العدد الكلي للعناصر.

### Error

```json
{
  "success": false,
  "message": "غير مصرح لك بالوصول",
  "errors": {}
}
```

### Validation Error (422)

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email field is required."]
  }
}
```

### HTTP Status Codes

| Code | المعنى |
|------|--------|
| 200 | نجاح |
| 201 | تم الإنشاء (register) |
| 401 | غير مصرح — Token مفقود/غير صالح |
| 403 | ممنوع — لا صلاحية أو enrollment غير مفعّل |
| 404 | المورد غير موجود |
| 422 | Validation error |

---

## Flutter Integration Notes

| البيئة | Base URL |
|--------|----------|
| Development (local) | `http://127.0.0.1:8000/api/v1` |
| Android Emulator | `http://10.0.2.2:8000/api/v1` |
| iOS Simulator | `http://127.0.0.1:8000/api/v1` |

### Required Headers (Protected routes)

```http
Authorization: Bearer YOUR_TOKEN
Accept: application/json
Content-Type: application/json
```

### Flutter parsing tips

1. **Login:** احفظ `response.data.token` و `response.data.user`
2. **Lists:** اقرأ `response.data` (array) + `response.meta.total`
3. **Errors:** تحقق من `success === false` ثم اعرض `message`
4. **Validation:** اقرأ `errors` field-by-field
5. **401:** امسح Token وأعد توجيه المستخدم لتسجيل الدخول

### Demo credentials

| Email | Password |
|-------|----------|
| student@rshdacademy.com | password |

---

## Public Endpoints

### POST /register

| | |
|---|---|
| **Auth** | No |
| **Role** | Student only (auto-assigned) |

**Request body:**

```json
{
  "name": "أحمد محمد",
  "email": "ahmed@example.com",
  "phone": "0500000000",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Success (201):**

```json
{
  "success": true,
  "message": "تم إنشاء الحساب بنجاح.",
  "data": {
    "token": "1|xxxxxxxx",
    "user": {
      "id": 4,
      "name": "أحمد محمد",
      "email": "ahmed@example.com",
      "phone": "0500000000",
      "role": "student",
      "status": "active",
      "email_verified_at": null,
      "password_set_at": "2026-06-29T12:00:00.000000Z",
      "created_at": "2026-06-29T12:00:00.000000Z",
      "updated_at": "2026-06-29T12:00:00.000000Z"
    }
  }
}
```

**Validation error (422):**

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email has already been taken."]
  }
}
```

**Notes:** الطالب الجديد `status=active` لكن لا يرى مواد حتى يُفعَّل enrollment من لوحة التحكم.

---

### POST /login

| | |
|---|---|
| **Auth** | No |

**Request body:**

```json
{
  "email": "student@rshdacademy.com",
  "password": "password"
}
```

**Success (200):**

```json
{
  "success": true,
  "message": "تم تسجيل الدخول بنجاح.",
  "data": {
    "token": "2|xxxxxxxx",
    "user": {
      "id": 3,
      "name": "Demo Student",
      "email": "student@rshdacademy.com",
      "phone": null,
      "role": "student",
      "status": "active",
      "email_verified_at": null,
      "password_set_at": "2026-06-29T12:00:00.000000Z",
      "created_at": "2026-06-29T12:00:00.000000Z",
      "updated_at": "2026-06-29T12:00:00.000000Z"
    }
  }
}
```

**Error — wrong credentials (422):**

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The provided credentials are incorrect."]
  }
}
```

**Error — blocked account (422):**

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "email": ["Your account has been blocked."]
  }
}
```

**Error — instructor without password (403):**

```json
{
  "success": false,
  "message": "يجب تعيين كلمة المرور أولاً من رابط الدعوة المرسل إلى بريدك.",
  "errors": {}
}
```

---

## Protected Endpoints

> جميع المسارات التالية تتطلب: `Authorization: Bearer TOKEN`

---

### POST /logout

**Request body:** none

**Success (200):**

```json
{
  "success": true,
  "message": "تم تسجيل الخروج بنجاح.",
  "data": null
}
```

---

### GET /me

**Success (200):**

```json
{
  "success": true,
  "data": {
    "id": 3,
    "name": "Demo Student",
    "email": "student@rshdacademy.com",
    "phone": null,
    "role": "student",
    "status": "active",
    "email_verified_at": null,
    "password_set_at": "2026-06-29T12:00:00.000000Z",
    "created_at": "2026-06-29T12:00:00.000000Z",
    "updated_at": "2026-06-29T12:00:00.000000Z"
  }
}
```

**Error (401):** Token missing or invalid.

---

### GET /my-subjects

| | |
|---|---|
| **Role** | Student only |

**Success (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "instructor_id": 2,
      "title": "أساسيات التشريح",
      "description": "مادة تجريبية لأساسيات التشريح",
      "category": "medicine",
      "cover_image": null,
      "status": "active",
      "price": "50.00",
      "created_at": "2026-06-29T12:00:00.000000Z",
      "updated_at": "2026-06-29T12:00:00.000000Z",
      "instructor": {
        "id": 2,
        "name": "Demo Instructor",
        "email": "instructor@rshdacademy.com",
        "phone": null,
        "role": "instructor",
        "status": "active",
        "email_verified_at": null,
        "password_set_at": "2026-06-29T12:00:00.000000Z",
        "created_at": "2026-06-29T12:00:00.000000Z",
        "updated_at": "2026-06-29T12:00:00.000000Z"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 1,
    "total": 1
  }
}
```

**Notes:** يعرض فقط المواد التي `payment_status=paid` و `access_status=active`.

**Error (403):** مستخدم ليس طالباً.

---

### GET /subjects/{subject}/lessons

**Success (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "subject_id": 1,
      "title": "محاضرة 1",
      "description": null,
      "order": 1,
      "status": "active",
      "created_at": "2026-06-29T12:00:00.000000Z",
      "updated_at": "2026-06-29T12:00:00.000000Z",
      "videos": [
        {
          "id": 1,
          "lesson_id": 1,
          "title": "فيديو تجريبي",
          "storage_provider": "demo",
          "video_url": "https://example.com/video.mp4",
          "duration_seconds": null,
          "status": "ready",
          "created_at": "2026-06-29T12:00:00.000000Z",
          "updated_at": "2026-06-29T12:00:00.000000Z"
        }
      ],
      "files": [
        {
          "id": 1,
          "lesson_id": 1,
          "title": "ملف PDF تجريبي",
          "file_type": "pdf",
          "file_url": "https://example.com/file.pdf",
          "file_size": null,
          "created_at": "2026-06-29T12:00:00.000000Z",
          "updated_at": "2026-06-29T12:00:00.000000Z"
        }
      ]
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 2,
    "total": 2
  }
}
```

**Error (403):** الطالب غير مشترك/غير مفعّل في المادة.

---

### GET /lessons/{lesson}

**Success (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "subject_id": 1,
    "title": "محاضرة 1",
    "description": null,
    "order": 1,
    "status": "active",
    "created_at": "2026-06-29T12:00:00.000000Z",
    "updated_at": "2026-06-29T12:00:00.000000Z",
    "subject": { "id": 1, "title": "أساسيات التشريح" },
    "videos": [],
    "files": []
  }
}
```

---

### GET /videos/{video}

**Success (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "lesson_id": 1,
    "title": "فيديو تجريبي",
    "storage_provider": "demo",
    "video_url": "https://example.com/video.mp4",
    "duration_seconds": null,
    "status": "ready",
    "created_at": "2026-06-29T12:00:00.000000Z",
    "updated_at": "2026-06-29T12:00:00.000000Z",
    "lesson": { "id": 1, "title": "محاضرة 1" },
    "progress": {
      "watched_seconds": 120,
      "current_position": 120,
      "completion_percentage": "0.00",
      "replay_count": 0,
      "last_watched_at": "2026-06-29T12:30:00.000000Z"
    }
  }
}
```

> `progress` يظهر للطالب فقط إذا وُجد سجل تقدم.

**Error (403):** لا enrollment نشط.

---

### POST /videos/{video}/progress

**Request body:**

```json
{
  "watched_seconds": 120,
  "current_position": 120,
  "replay_count": 0
}
```

**Success (200):**

```json
{
  "success": true,
  "message": "تم تحديث تقدم المشاهدة بنجاح.",
  "data": {
    "watched_seconds": 120,
    "current_position": 120,
    "completion_percentage": "0.00",
    "replay_count": 0,
    "last_watched_at": "2026-06-29T12:30:00.000000Z"
  }
}
```

---

### GET /files/{file}

**Success (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "lesson_id": 1,
    "title": "ملف PDF تجريبي",
    "file_type": "pdf",
    "file_url": "https://example.com/file.pdf",
    "file_size": null,
    "created_at": "2026-06-29T12:00:00.000000Z",
    "updated_at": "2026-06-29T12:00:00.000000Z",
    "lesson": { "id": 1, "title": "محاضرة 1" }
  }
}
```

---

### GET /files/{file}/annotations

**Success (200):**

```json
{
  "success": true,
  "data": {
    "annotation_json": {
      "page": 1,
      "notes": "ملاحظة الطالب"
    }
  }
}
```

> إذا لا توجد ملاحظات: `"annotation_json": null`

---

### POST /files/{file}/annotations

**Request body:**

```json
{
  "annotation_json": {
    "page": 1,
    "notes": "ملاحظة الطالب"
  }
}
```

**Success (200):**

```json
{
  "success": true,
  "message": "تم حفظ الملاحظات بنجاح.",
  "data": {
    "annotation_json": {
      "page": 1,
      "notes": "ملاحظة الطالب"
    }
  }
}
```

---

### GET /assignments

**Success (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "subject_id": 1,
      "lesson_id": 1,
      "title": "واجب 1",
      "description": null,
      "due_date": null,
      "status": "active",
      "created_at": "2026-06-29T12:00:00.000000Z",
      "updated_at": "2026-06-29T12:00:00.000000Z",
      "subject": { "id": 1, "title": "أساسيات التشريح" },
      "lesson": { "id": 1, "title": "محاضرة 1" },
      "submissions": []
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 1, "total": 1 }
}
```

**Notes:** الطالب يرى واجبات مواده المفعلة فقط.

---

### POST /assignments/{assignment}/submit

**Request body:**

```json
{
  "answer_text": "إجابة الطالب",
  "file_url": "https://example.com/answer.pdf"
}
```

**Success (200):**

```json
{
  "success": true,
  "message": "تم تسليم الواجب بنجاح.",
  "data": {
    "id": 1,
    "assignment_id": 1,
    "answer_text": "إجابة الطالب",
    "file_url": "https://example.com/answer.pdf",
    "submitted_at": "2026-06-29T12:00:00.000000Z"
  }
}
```

---

### GET /quizzes

**Success (200):** نفس شكل list مع `QuizResource` objects.

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "subject_id": 1,
      "lesson_id": null,
      "title": "اختبار 1",
      "description": null,
      "duration_minutes": 30,
      "status": "active",
      "created_at": "2026-06-29T12:00:00.000000Z",
      "updated_at": "2026-06-29T12:00:00.000000Z"
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 1, "total": 1 }
}
```

---

### POST /quizzes/{quiz}/start

**Request body:** none

**Success (200):**

```json
{
  "success": true,
  "message": "تم بدء الاختبار بنجاح.",
  "data": {
    "attempt_id": 1,
    "quiz": {
      "id": 1,
      "title": "اختبار 1",
      "questions": [
        {
          "id": 1,
          "question_text": "السؤال الأول؟",
          "question_type": "mcq",
          "points": 1,
          "answers": [
            { "id": 1, "answer_text": "الإجابة أ" },
            { "id": 2, "answer_text": "الإجابة ب" }
          ]
        }
      ]
    }
  }
}
```

> **مهم:** `is_correct` مخفي عن الطالب في start.

---

### POST /quizzes/{quiz}/submit

**Request body:**

```json
{
  "answers": [
    { "question_id": 1, "answer_id": 1 },
    { "question_id": 2, "answer_text": "إجابة نصية" }
  ]
}
```

**Success (200):**

```json
{
  "success": true,
  "message": "تم تسليم الاختبار بنجاح.",
  "data": {
    "attempt_id": 1,
    "score": 85.5
  }
}
```

---

### GET /grades

**Success (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "student_id": 3,
      "subject_id": 1,
      "source_type": "quiz",
      "source_id": 1,
      "grade": "85.50",
      "notes": null,
      "created_at": "2026-06-29T12:00:00.000000Z",
      "updated_at": "2026-06-29T12:00:00.000000Z",
      "subject": { "id": 1, "title": "أساسيات التشريح" }
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 1, "total": 1 }
}
```

**Notes:** الطالب يرى درجاته فقط.

---

### GET /notifications

**Success (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": 3,
      "title": "إشعار تجريبي",
      "body": "محتوى الإشعار",
      "type": "general",
      "is_read": false,
      "created_at": "2026-06-29T12:00:00.000000Z",
      "updated_at": "2026-06-29T12:00:00.000000Z"
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 1, "total": 1 }
}
```

---

### POST /notifications/{notification}/read

**Request body:** none

**Success (200):**

```json
{
  "success": true,
  "message": "تم تعليم الإشعار كمقروء.",
  "data": {
    "id": 1,
    "user_id": 3,
    "title": "إشعار تجريبي",
    "body": "محتوى الإشعار",
    "type": "general",
    "is_read": true,
    "created_at": "2026-06-29T12:00:00.000000Z",
    "updated_at": "2026-06-29T12:00:00.000000Z"
  }
}
```

**Error (403):** محاولة قراءة إشعار طالب آخر.

---

## cURL Examples

### Login

```bash
curl -X POST http://127.0.0.1:8000/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "email": "student@rshdacademy.com",
    "password": "password"
  }'
```

### Get my-subjects

```bash
curl http://127.0.0.1:8000/api/v1/my-subjects \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Update video progress

```bash
curl -X POST http://127.0.0.1:8000/api/v1/videos/1/progress \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "watched_seconds": 120,
    "current_position": 120,
    "replay_count": 0
  }'
```

---

## Resource Field Reference

| Resource | Key fields for Flutter |
|----------|------------------------|
| User | `id`, `name`, `email`, `role`, `status` |
| Subject | `id`, `title`, `category`, `price`, `instructor` |
| Lesson | `id`, `title`, `order`, `videos[]`, `files[]` |
| Video | `id`, `video_url`, `duration_seconds`, `progress` |
| LessonFile | `id`, `file_url`, `file_type` |
| Assignment | `id`, `title`, `due_date`, `submissions` |
| Quiz | `id`, `title`, `duration_minutes`, `questions` |
| Grade | `id`, `grade`, `source_type`, `subject` |
| Notification | `id`, `title`, `body`, `is_read` |

---

## Known Limitations / Future

1. **Pagination:** `meta` موجود لكن pagination فعلي (`?page=`) غير مفعّل بعد.
2. **Device binding:** `device_id` غير مطلوب في login/register حالياً.
3. **File upload:** `file_url` يُرسل كنص؛ رفع ملفات فعلي لاحقاً.
4. **Refresh token:** Sanctum personal access token فقط — لا refresh token منفصل.

---

*Last updated: API Contract v1 — aligned with unified JSON envelope.*
