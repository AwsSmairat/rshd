<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>صيانة المنصة — RSHD</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --navy: #0B1F3A;
            --gold: #D6B56D;
            --ivory: #F6F1E7;
            --text: #111827;
            --muted: #6B7280;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 1.5rem;
            font-family: "Cairo", sans-serif;
            background: linear-gradient(180deg, var(--ivory) 0%, #fff 100%);
            color: var(--text);
        }

        .card {
            width: min(100%, 34rem);
            background: #fff;
            border: 1px solid #E5E7EB;
            border-radius: 1.25rem;
            padding: 2rem 1.75rem;
            text-align: center;
            box-shadow: 0 18px 40px rgba(11, 31, 58, 0.08);
        }

        .badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 4rem;
            height: 4rem;
            border-radius: 999px;
            background: linear-gradient(135deg, var(--gold), #B88A32);
            color: var(--navy);
            font-weight: 800;
            font-size: 1.1rem;
            margin-bottom: 1rem;
        }

        h1 {
            margin: 0 0 0.75rem;
            font-size: 1.5rem;
            color: var(--navy);
        }

        p {
            margin: 0;
            line-height: 1.8;
            color: var(--muted);
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="badge">RSHD</div>
        <h1>المنصة تحت الصيانة</h1>
        <p>{{ $message }}</p>
    </div>
</body>
</html>
