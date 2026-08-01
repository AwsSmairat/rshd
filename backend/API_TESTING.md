# RSHD API Testing Guide

دليل مختصر لاختبار API قبل ربط تطبيق Flutter.

## تشغيل السيرفر

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve
```

السيرفر الافتراضي: `http://localhost:8000`  
Base URL للـ API: `http://localhost:8000/api/v1`

## Headers المطلوبة

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

## بيانات الدخول التجريبية

| الدور | Email | Password |
|-------|-------|----------|
| Admin | admin@rshdacademy.com | password |
| Instructor | instructor@rshdacademy.com | password |
| Student | student@rshdacademy.com | password |

> Register API مخصص للطلاب فقط.

---

## 1. Login

```bash
curl -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "email": "student@rshdacademy.com",
    "password": "password"
  }'
```

**Response:**

```json
{
  "data": {
    "token": "1|xxxx",
    "user": { "id": 3, "name": "Demo Student", "role": "student", ... }
  }
}
```

احفظ `token` واستخدمه في `Authorization: Bearer ...`

---

## 2. Me

```bash
curl http://localhost:8000/api/v1/me \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 3. My Subjects (مواد الطالب المفعلة)

```bash
curl http://localhost:8000/api/v1/my-subjects \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

يعرض فقط المواد التي: `payment_status=paid` و `access_status=active`

---

## 4. Lessons

```bash
curl http://localhost:8000/api/v1/subjects/1/lessons \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl http://localhost:8000/api/v1/lessons/1 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 5. Videos + Progress

```bash
curl http://localhost:8000/api/v1/videos/1 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl -X POST http://localhost:8000/api/v1/videos/1/progress \
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

## 6. Files + Annotations

```bash
curl http://localhost:8000/api/v1/files/1 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl http://localhost:8000/api/v1/files/1/annotations \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl -X POST http://localhost:8000/api/v1/files/1/annotations \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "annotation_json": {
      "page": 1,
      "notes": "ملاحظة تجريبية"
    }
  }'
```

---

## 7. Assignments

```bash
curl http://localhost:8000/api/v1/assignments \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl -X POST http://localhost:8000/api/v1/assignments/1/submit \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "answer_text": "إجابة تجريبية"
  }'
```

---

## 8. Quizzes

```bash
curl http://localhost:8000/api/v1/quizzes \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl -X POST http://localhost:8000/api/v1/quizzes/1/start \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl -X POST http://localhost:8000/api/v1/quizzes/1/submit \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "answers": [
      { "question_id": 1, "answer_id": 1 }
    ]
  }'
```

---

## 9. Grades & Notifications

```bash
curl http://localhost:8000/api/v1/grades \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl http://localhost:8000/api/v1/notifications \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl -X POST http://localhost:8000/api/v1/notifications/1/read \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 10. Register (Student)

```bash
curl -X POST http://localhost:8000/api/v1/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "New Student",
    "email": "newstudent@example.com",
    "password": "password",
    "password_confirmation": "password"
  }'
```

---

## 11. Logout

```bash
curl -X POST http://localhost:8000/api/v1/logout \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Endpoints الأساسية لتطبيق Flutter

| Method | Endpoint | الغرض |
|--------|----------|-------|
| POST | `/register` | تسجيل طالب |
| POST | `/login` | تسجيل الدخول + Token |
| GET | `/me` | بيانات المستخدم |
| GET | `/my-subjects` | قائمة المواد |
| GET | `/subjects/{id}/lessons` | دروس المادة |
| GET | `/lessons/{id}` | تفاصيل درس |
| GET | `/videos/{id}` | تفاصيل فيديو |
| POST | `/videos/{id}/progress` | تحديث التقدم |
| GET | `/files/{id}` | ملف الدرس |
| GET/POST | `/files/{id}/annotations` | ملاحظات PDF |
| GET | `/assignments` | الواجبات |
| POST | `/assignments/{id}/submit` | تسليم واجب |
| GET | `/quizzes` | الاختبارات |
| POST | `/quizzes/{id}/start` | بدء اختبار |
| POST | `/quizzes/{id}/submit` | تسليم اختبار |
| GET | `/grades` | الدرجات |
| GET | `/notifications` | الإشعارات |
| POST | `/notifications/{id}/read` | قراءة إشعار |
| POST | `/logout` | تسجيل الخروج |

---

## ملاحظات Flutter

1. احفظ Token في secure storage.
2. أرسل `Authorization: Bearer {token}` مع كل طلب محمي.
3. عند `401` امسح Token وأعد توجيه المستخدم لتسجيل الدخول.
4. `device_id` / `platform` جاهزان في `DeviceService` لكن **لم يُفعّلا بعد** في login/register.
5. الطالب لا يرى محتوى إلا بعد تفعيل enrollment من لوحة التحكم.
