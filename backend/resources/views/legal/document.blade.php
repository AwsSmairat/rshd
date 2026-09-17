@extends('legal.layout')

@section('title', $document->title)
@section('description', $document->subtitle ?: $document->title)
@section('canonical', $type === \App\Enums\LegalDocumentType::PrivacyPolicy ? '/privacy-policy' : '/terms')

@section('content')
    <article class="legal-document">
        <header class="legal-hero">
            <span class="legal-kicker">
                {{ $type === \App\Enums\LegalDocumentType::PrivacyPolicy ? 'الخصوصية وحماية البيانات' : 'الشروط القانونية' }}
            </span>

            <h1>{{ $document->title }}</h1>

            @if ($document->subtitle)
                <p>{{ $document->subtitle }}</p>
            @endif

            <div class="legal-meta">
                <span>الإصدار {{ $document->version }}</span>

                @if ($document->published_at)
                    <span>آخر تحديث: {{ $document->published_at->format('Y/m/d') }}</span>
                @endif
            </div>
        </header>

        @if ($document->summary)
            <section class="legal-summary">
                <p>{{ $document->summary }}</p>
            </section>
        @endif

        <div class="legal-sections">
            @foreach (($document->sections ?? []) as $section)
                <section class="legal-section" id="{{ $section['id'] ?? 'section-'.$loop->iteration }}">
                    <h2>{{ $section['title'] ?? '' }}</h2>

                    @foreach (($section['paragraphs'] ?? []) as $paragraph)
                        <p>{{ $paragraph }}</p>
                    @endforeach

                    @if (! empty($section['bullet_points']))
                        <ul>
                            @foreach ($section['bullet_points'] as $item)
                                <li>{{ $item }}</li>
                            @endforeach
                        </ul>
                    @endif

                    @foreach (($section['subsections'] ?? []) as $subsection)
                        <div class="legal-subsection">
                            @if (! empty($subsection['title']))
                                <h3>{{ $subsection['title'] }}</h3>
                            @endif

                            @if (! empty($subsection['items']))
                                <ul>
                                    @foreach ($subsection['items'] as $item)
                                        <li>{{ $item }}</li>
                                    @endforeach
                                </ul>
                            @endif
                        </div>
                    @endforeach
                </section>
            @endforeach
        </div>
    </article>
@endsection
