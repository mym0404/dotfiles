# mjstudio-vibe 프로젝트 규칙

## 프로젝트

- 로컬 저장소: `/Users/mj/projects/mjstudio-vibe`
- 전역 스킬: `/Users/mj/.codex/skills/vibe-mjstudio`
- GitHub 저장소: `https://github.com/mym0404/vibe-mjstudio`
- 배포: Vercel
- 공개 도메인: `https://vibe.mjstudio.net`
- 패키지 관리자: `pnpm`
- 애플리케이션: Next.js App Router
- 디자인 원본: `/Users/mj/projects/mjstudio-vibe/DESIGN.md`

실제 구현과 이 문서가 다르면 현재 저장소의 코드와 `DESIGN.md`를 기준으로 이 참조를 갱신한다. Next.js 코드를 바꾸기 전에는 저장소의 `AGENTS.md` 지시에 따라 설치된 Next.js 버전의 `node_modules/next/dist/docs/`에서 관련 가이드를 읽는다.

## 먼저 읽을 코드

문서를 추가하거나 수정할 때 다음 파일을 확인한다.

- `AGENTS.md`: 저장소 작업 규칙
- `DESIGN.md`: Figma Dark의 색, 타이포그래피, 간격, shape, 표면과 컴포넌트 디자인 기준
- `lib/report-loader.ts`: 문서 파일 발견, `ReportMeta` 타입과 메타데이터 변환
- `app/page.tsx`: 날짜 최신순 문서 목록
- `app/docs/[slug]/page.tsx`: 모든 문서가 공유하는 주소와 레이아웃 연결. 문서별 등록 목록은 두지 않는다.
- `components/report-layout.tsx`: `ReportLayout`과 h1·요약·날짜·읽기 시간·본문 배치
- `components/key-takeaway.tsx`: 흰 배경·왼쪽 종이 굴곡으로 가장 중요한 내용을 보여주는 `KeyTakeaway`
- `components/ui.tsx`: `Text`, `Section`, `Card`, `Callout`, `InlineCode`, `Mark`, `DataTable`, `ColorBlock`, `Evidence`
- `components/controls.tsx`: `Tabs`
- `components/code-block.tsx`: Shiki 기반 `CodeBlock`과 공용 언어·복사 상태 UI
- `components/code-language-icon.tsx`: TSX·TypeScript·CSS·JSON·Kotlin·Swift용 공용 Simple Icons 언어 아이콘
- `components/file-tree.tsx`: `FileTree`
- `components/ambient-blocks.tsx`: 홈 키캡과 갤러리의 `contained` 미리보기
- `components/timeline.tsx`: `Timeline`
- `components/relative-time.tsx`: 날짜와 한국어 상대 시간을 표시하는 `RelativeTime`
- `components/source-link.tsx`: `SourceLink`, `DecisionLink`
- `content/reports/<slug>.tsx`: 문서 하나의 `report` 메타데이터, 본문과 선택적인 `Video`
- `content/gallery-demos.tsx`: 갤러리에서 사용하는 공용 표현 예시
- `styles/tokens.stylex.ts`: StyleX 색·글꼴·간격·곡률 토큰
- `app/globals.css`: 전역 스타일과 StyleX 설정에 필요한 공용 CSS

컴포넌트 이름, props와 import 경로는 기억으로 작성하지 않고 현재 구현에서 확인한다. 공용 구현이 있으면 문서별로 다시 만들지 않는다. 새 공용 컴포넌트를 추가하면 이 절에 실제 경로와 역할을 기록한다. 공용 컴포넌트를 추가·변경할 때는 `content/reports/component-gallery.tsx`에도 실제 구현을 사용하는 예시와 주요 변형·상태를 반영한다. 페이지 자체의 ReportLayout·KeyTakeaway와 CodeBlock 내부의 언어 아이콘·복사 버튼은 중복 구현하지 않고 전체 컴포넌트 목록에서 예시 위치를 밝힌다.

현재 컴포넌트 계약은 다음과 같다.

| 컴포넌트 | 핵심 props |
| --- | --- |
| `ReportLayout` | `report: ReportMeta`, `video?: ReactNode`, `children` |
| `KeyTakeaway` | `title: string`, `body: ReactNode` |
| `Text` | `variant?: "body" \| "small" \| "eyebrow"`, `className?`, `xstyle?`, `children` |
| `Section` | `id`, `title`, `children` |
| `Card` | `className?`, `xstyle?`, `children` |
| `Callout` | `tone?: "info" \| "warning" \| "success"`, `children` |
| `InlineCode` | `children` |
| `Mark` | `children` |
| `DataTable` | `columns: string[]`, `rows: ReactNode[][]` |
| `ColorBlock` | `name`, `value`, `description?` |
| `Evidence` | `kind: "interpretation" \| "proposal" \| "unverified"`, `children` |
| `Tabs` | `label`, `items: { id, label, content }[]` |
| `CodeBlock` | `code`, `filename`, `language?: "tsx" \| "typescript" \| "json" \| "css" \| "kotlin" \| "swift"` |
| `AmbientBlocks` | `contained?: boolean` — 갤러리에서는 카드 안에 배치 |
| `FileTree` | `label`, `nodes: FileTreeNode[]` |
| `Timeline` | `items: { id, title, content, label?, date? }[]`, `initialStep?`, `interactive?`, `progress?` |
| `RelativeTime` | `dateTime: string`, `showDate?: boolean` |
| `SourceLink` | `href`, `children`, `preview?: SourcePreview`, `xstyle?`, `variant?: "text" \| "button"` |
| `DecisionLink` | `href`, `decision`, `context`, `children`, `preview?: SourcePreview` |

`SourcePreview`는 확인한 GitHub PR에만 사용하며 `title`, `author`, `state: "merged" | "open" | "closed" | "draft"`를 요구한다. 확인한 `createdAt`·`updatedAt`·`mergedAt`·`closedAt`을 ISO 8601 문자열로 전달하면 생성·수정·병합·종료 상대 시간이 표시된다. 날짜는 선택 필드이며 확인하지 못한 시각은 생략한다. `SourceLink`와 `DecisionLink`가 같은 내부 서비스 판별과 preview tooltip을 사용하므로 문서에서 아이콘이나 tooltip을 다시 구현하지 않는다.

`DataTable.rows`의 셀, `Card`·`Callout`의 본문과 `ReportMeta.takeaway.body`는 JSX를 받는다. 이 영역에서 코드 이름·함수·경로·옵션·리터럴을 쓸 때 문자열 전체가 아니라 식별자만 `InlineCode`로 감싼다. 공용 `InlineCode`는 주변 글자색에서 배경과 경계색을 만들어 어두운 표·카드와 밝은 핵심 요약·안내 카드에서 같은 방식으로 구분한다. `ReportMeta.title`·`summary`와 `takeaway.title`은 문자열로 유지한다.

`Timeline`은 마일스톤과 변경 이력에 함께 사용한다. 항목의 `date`에 확인한 날짜(`YYYY-MM-DD`)나 시간대가 있는 ISO 8601 시각을 전달한다. 날짜를 `label`에 넣지 않는다. 공용 `RelativeTime`이 정확한 날짜와 `3일 전`·`2일 후`·`오늘`을 함께 표시한다. 날짜만 있는 일정은 한국 시간의 날짜를 기준으로 계산하고, 시각은 분·시간·일·개월·년으로 표시한다. 브라우저에서 매분 및 창 포커스 복귀 시 갱신하며 날짜 hover에 정확한 KST 시각을 유지한다. 예시 일정은 본문에서 예시임을 밝히고 실제 일정으로 서술하지 않는다. `progress`를 생략하면 `interactive` 값을 따르고, 마일스톤은 현재 단계까지 연결선을 채운다. 변경 이력은 `progress={false}`로 같은 구조를 유지하며 진행 상태를 표시하지 않는다. 상태 표현은 공용 Timeline의 라일락 노드·연결선과 어두운 표면 차이를 재사용한다. 문서에서 초록 상태색이나 흰 선택 테두리를 덧씌우지 않는다. 단계 전환 전후 카드의 테두리·위치·크기가 바뀌지 않고 완료 체크와 단계 번호가 작은 화면에서도 구분되는지 확인한다.

문서 본문과 모바일에는 목차를 만들지 않는다. `ReportLayout`은 제목·요약·날짜·영상이 있다면 영상·핵심 요약 다음에 본문을 둔다. 1280px 이상에서는 공용 `SectionWheel`이 렌더된 `Section`의 제목과 `id`를 읽어 오른쪽 여백에 표시한다. 라벨은 한 줄로 유지하고, 클릭하면 해당 섹션으로 부드럽게 이동하며, 휠은 활성 섹션이 바뀔 때만 움직인다. `ReportMeta`에 목차용 `sections`나 `showToc` 필드를 추가하지 않고 모바일 접힘 목록도 만들지 않는다. 넓은 표는 본문 오른쪽 경계에 맞춰 왼쪽으로 확장하되 최대 960px에서 멈춘다.

요청마다 에이전트가 판단하고 수행할 조사·작성·검증·배포 절차와 사이트가 같은 입력에 항상 같은 결과를 내야 할 UI 규칙을 구분한다. 전자는 `SKILL.md`와 `references/`에 기록하고, 색·아이콘·밑줄·tooltip·PR 상태처럼 결정적인 형태와 상호작용은 공용 컴포넌트와 토큰에 구현한다. `$vibe-mjstudio`를 명시적으로 호출하면 별도 스킬 이름을 요구하지 않고 이 프로젝트 참조를 모두 적용한다.

## Git 절차

1. 현재 브랜치, 작업 트리, 등록된 원격과 추적 브랜치를 확인한다. 사용자 변경을 보존하고 이번 요청과 겹치는 파일은 내용을 먼저 읽는다.
2. 추적 원격 브랜치가 있으면 `git pull --ff-only`로 최신 커밋을 가져온다. 원격이나 추적 브랜치가 없으면 임의의 대상을 만들지 말고, 이미 확정된 GitHub 저장소 설정만 적용한다.
3. 요청한 문서와 필요한 공용 구현만 수정한다. 무관한 변경을 커밋에 포함하지 않는다.
4. [검증](#검증)에 따라 변경 유형에 필요한 검사를 통과한 뒤 Conventional Commits 형식으로 커밋한다.
5. 현재 브랜치의 추적 원격 브랜치에 push하고 원격 커밋을 확인한다.
6. Vercel 배포가 완료되면 `https://vibe.mjstudio.net`에서 새 목록 항목과 상세 페이지를 직접 확인한다.

`$vibe-mjstudio`로 문서 작성·수정을 요청한 경우 위 pull·commit·push는 사용자에게 다시 묻지 않고 수행한다. 브랜치 변경, worktree와 PR 생성은 사용자가 별도로 요청했을 때만 수행한다.

## 스타일과 시각화

아래 규칙은 새 문서에서 공용 컴포넌트를 사용하는 기준이다. 이미 구현된 컴포넌트나 StyleX 토큰의 내부 동작·스타일은 매 문서 작업마다 다시 검증하지 않는다. 이번 작업에서 새로 만들거나 수정한 공용 구현만 세부 검증하고, 기존 구현을 그대로 사용한 문서는 실제 표시 결과만 확인한다.

- 모든 글의 첫머리에 `ReportMeta.takeaway`로 가장 중요한 결론과 그 결론을 이해하는 데 필요한 맥락을 작성한다. `ReportLayout`이 공용 `KeyTakeaway`를 흰 배경·어두운 글자·왼쪽 뜯긴 종이 모양으로 렌더하므로 문서별 카드를 중복으로 넣지 않는다. `summary`는 제목 아래의 개요로 유지한다. 영상이 있으면 `ReportLayout`의 `video` prop에 전달하고 순서는 제목·메타데이터 → 영상 → 핵심 요약 → 본문으로 둔다. 영상이 없으면 핵심 요약부터 시작하며 빈 영상 영역을 만들지 않는다.
- 색, 타이포그래피, 간격, shape와 표면은 `DESIGN.md`의 Figma Dark 토큰을 사용한다.
- 본문과 UI의 현재 글꼴 계약은 `DESIGN.md`를 따르고, 코드 블록과 인라인 코드는 `fonts.mono`의 D2Coding을 사용한다.
- 코드 블록의 글꼴을 검증할 때는 바깥 `pre`뿐 아니라 내부 `code`·문법 토큰·줄번호의 실제 렌더 스타일을 확인한다. iOS 첫 로드와 탭 전환 후에도 토큰·줄번호가 같은 12px을 유지하도록 공용 `pre`의 `text-size-adjust: 100%`·`-webkit-text-size-adjust: 100%`를 보존한다. 탭별 글자 크기 보정이나 브라우저 확대 제한을 추가하지 않는다. 브라우저 기본 고정폭 글꼴이 남아 있지 않아야 하며, 글자 크기와 줄높이는 `DESIGN.md`의 코드 타이포그래피와 일치해야 한다.
- 공용 패널 내부는 `spacing.panel`, 코드 블록 헤더·본문의 좌우 여백은 `spacing.codeInline`(8px), 코드 본문의 상하 여백은 `spacing.code`(12px), 형제 패널 사이는 `spacing.card`를 사용한다. 코드 줄번호는 3ch, 줄번호 뒤 간격은 12px로 두고 상태 기호가 이 간격 안에 들어가는지 확인한다. 줄마다 오른쪽 여백을 중복 적용하지 않는다. 문서별 스타일로 이 역할을 합치거나 다시 숫자로 선언하지 않는다.
- 코드 예시는 모든 문서에서 공용 `CodeBlock`과 `CodeLanguageIcon`, 아이콘 전용 복사 상태 UI를 사용한다. 공용 코드 블록은 기본적으로 긴 줄과 공백 없는 긴 토큰도 프레임 안에서 줄바꿈한다. 이어지는 시각적 줄은 줄번호 뒤의 코드 시작점에 맞추고 줄번호는 원본 줄마다 한 번만 표시한다. 복사 결과는 원본 줄바꿈과 들여쓰기를 유지한다. 언어 아이콘 경로나 복사·성공·오류 아이콘을 문서별로 다시 만들지 않는다.
- 중요한 짧은 구절은 공용 `Mark`의 파란색 `#2563eb` 붓 자국과 흰 글자를 사용한다. 이전 보라색 붓 자국은 거친 가장자리와 붓결의 질감만 참고한다. 출처가 있는 중요한 사실·결정·원문 요약은 `DecisionLink`의 빨간색 `#d94646` 붓 자국과 흰 글자를 사용한다. 줄바꿈에서는 각 줄의 붓 자국과 안쪽 여백을 이어 표시한다.
- 사실·해석·제안·미확인의 구분과 문장 순서는 [글쓰기 기준](writing.md)을 함께 적용한다. 해석·제안·미확인은 공용 `Evidence`를 사용하며 내용 14px·줄높이 1.8·`colors.mute`, 라벨 10px·불투명도 0.8을 유지한다. 제안과 일반 성공 표시는 `colors.accentGreen`의 세이지색(`#8fae9b`)을 사용하고 선명한 초록색 `#2ecc5b`로 되돌리지 않는다. GitHub PR 상태색은 별도 서비스 토큰을 유지한다.
- StyleX 테두리는 `borderWidth`·`borderStyle`·`borderColor`처럼 개별 속성으로 선언한다. `border`·`borderTop`·`borderBottom` 등 복합 shorthand를 사용하지 않는다. 형태 예시는 실제 렌더에서 테두리 두께·선 종류·색·곡률이 적용되어 외곽선을 구분할 수 있는지 확인한다.
- StyleX의 공용 토큰과 스타일을 우선 재사용한다. `xstyle` prop을 받는 공용 컴포넌트만 `xstyle`로 확장하고, 그 밖의 스타일은 문서 모듈의 `stylex.create`와 `stylex.props`로 적용한다.
- 문서 레이아웃, 본문 텍스트, 섹션, 카드, 표, 코드 블록, 타임라인, 파일 트리, 탭과 링크는 위 공용 구현과 실제 props를 확인해 사용한다.
- 파일 트리는 공용 `FileTree`를 사용한다. 공용 패널 여백의 예외로 헤더·본문 좌우 16px, 헤더 상하 8px·최소 높이 40px, 본문 상하 12px, 행 상하 4px·최소 높이 32px의 간결한 간격을 유지한다. 글자 13px·아이콘 15px·단계별 들여쓰기 28px은 유지하고 모바일에서 설명이 줄바꿈되면 행 높이가 늘어나게 한다. 기본 펼침·선택 불가를 유지하고 폴더 토글의 hover와 키보드 포커스에서 배경·화살표 강조를 확인한다. hover 자체로 폴더를 여닫지 않고 클릭·Enter·Space로만 전환한다. 효과는 행 크기나 들여쓰기를 바꾸지 않으며 파일 행에는 토글 효과를 붙이지 않는다. 터치와 reduced-motion에서도 동작을 확인하고 문서별 효과를 중복 구현하지 않는다.
- 출처가 있는 중요한 사실·결정·원문 요약은 `DecisionLink`로 연결하고 사실·요약·해석의 성격을 본문에서 정확히 구분한다. 형광펜 링크는 아이콘·글자에 밑줄을 표시하지 않으며 hover에도 추가하지 않는다. 일반 출처는 밑줄을 유지하는 `SourceLink`를 사용한다. 두 컴포넌트의 공용 내부 구현이 60개 이상 서비스 판별, 일반 링크의 아이콘부터 글 끝까지 이어지는 밑줄, PR 상태 아이콘 색과 hover·focus tooltip을 처리하므로 문서에서 다시 구현하지 않는다.
- `http:`·`https:` 링크는 공용 컴포넌트가 새 탭과 `rel="noopener noreferrer"`를 적용한다. 본문의 외부 이동 버튼도 `SourceLink variant="button"`의 `xstyle`을 사용해 기본·hover 상태에서 밑줄을 제거하며, 내부 문서 링크는 기존 내부 탐색을 유지한다.
- GitHub PR 링크는 실제 PR의 제목·작성자 이름 또는 계정·상태를 확인해 `SourcePreview`로 전달한다. 실제 PR이 없거나 metadata를 확인하지 못하면 가짜 preview를 만들지 않는다.
- 문서 전용 시각화는 해당 문서의 콘텐츠 모듈에 두되 색·간격·타이포그래피는 공용 토큰을 사용한다.
- 이미지에는 실제 크기나 고정 비율을 지정하고, 저장소에 최종 자산을 저장한다. 본문 너비를 넘지 않는지 모바일과 데스크톱에서 확인한다.
- 홈의 `F R E E :`는 타투 사진을 참고해 imagegen으로 각각 만든 투명 이미지 5개를 `AmbientBlocks`에서 재사용한다. 두 E도 별도 자산이며, 손으로 그린 윤곽·음영·기울기를 보존하고 SVG 도형으로 다시 만들지 않는다. 새 키캡을 요청받으면 imagegen으로 개별 생성하고 최종 파일을 `public/images/keycaps/`에 저장한다. favicon은 같은 타투 스타일의 단순화한 F이며 `app/icon.png`에서 관리한다. 모바일·태블릿·데스크톱에서 다섯 키가 본문을 가리지 않는지, 독립 부유 애니메이션과 reduced-motion이 유지되는지 검증한다.

## 문서 등록

새 문서는 `content/reports/<slug>.tsx` 파일 하나를 추가한다. 이 파일은 `report` 객체와 기본 export 본문 컴포넌트를 함께 가진다. `report`는 `title`, `summary`, `takeaway: { title, body }`, `date`, `readingMinutes`, `category`를 담고, slug는 파일명에서 정한다. 영상이 있으면 같은 파일에서 `Video` 컴포넌트를 export한다. 공용 `app/docs/[slug]/page.tsx`는 이 파일을 읽어 `ReportLayout`에 넣고 제목·설명·canonical URL·공유 메타데이터를 만든다. `lib/report-loader.ts`가 문서 파일을 자동으로 발견해 홈 목록과 사이트맵을 날짜 최신순으로 만든다. `lib/`이나 라우트에 수동 목록을 추가하지 않는다. 문서 파일의 제목·날짜·요약·읽기 시간이 목록과 상세에서 일치하고 새 파일만 추가해도 주소가 열리는지 확인한다.

## 검증

변경 유형을 먼저 확인하고 프로젝트의 `package.json` 스크립트를 기준으로 검사한다.

1. Markdown·스킬 문서만 바뀌었다면 변경한 문서의 내용·링크·관련 규칙을 확인한다. 스킬을 수정했다면 스킬 검증기를 실행한다. 사이트 코드가 바뀌지 않았으므로 `pnpm` 검사와 사이트 빌드는 실행하지 않는다.
2. TSX 문서의 본문 문구나 제목·요약·날짜·읽기 시간처럼 표시용 메타데이터 값만 바뀌고 JSX 구조·props·import·공용 컴포넌트·설정이 그대로라면 변경 파일 포맷과 `pnpm lint`를 확인하고 해당 페이지를 실제로 렌더한다. 로컬 typecheck·build는 생략하고 push 후 Vercel 빌드 결과를 확인한다.
3. JSX 구조·props·import·라우트·slug·공용 컴포넌트·StyleX·설정이 바뀌었다면 변경 파일 포맷 → `pnpm lint` → `pnpm exec tsc --noEmit` → `pnpm build` 순서로 확인한다.
4. 변경한 목록·상세 페이지는 모바일 390px과 데스크톱 1440px, 두 화면 너비에서 렌더한다. CSS 브레이크포인트의 직전·기준·직후 너비를 추가로 전수 검사하지 않는다. 브라우저 확대율을 고려해 실제 `innerWidth`를 기록하고, 두 너비에서 페이지 가로 넘침·본문 중앙 정렬·표의 확장·장식 요소의 잘림을 검증한다.
5. 추가하거나 수정한 탭, 파일 트리, tooltip, 외부·내부 링크 동작과 코드 복사·성공·오류 상태 등 실제 상호작용을 확인한다.
6. push 뒤 Vercel 배포 상태와 `https://vibe.mjstudio.net`의 실제 문서를 확인한다.

한 검사가 실패하면 원인을 이번 변경, 기존 오류, 환경 문제로 나눠 기록한다. 수정으로 영향을 받은 검사만 다시 실행하고, 해당 변경 유형에 필요한 검사가 통과했는지 확인한다. Vercel 빌드가 실패하면 원인을 고쳐 다시 검증한다.

같은 작업에서 이미 통과한 검사는 표시 내용의 작은 후속 수정 때문에 반복하지 않는다. 문구·오탈자·코드 발췌만 바뀌고 JSX 구조·props·import·스타일·자산·라우트·동작이 그대로라면 변경 부분의 내용·출처·포맷만 확인한다. 이전 실패를 고치거나 해당 검사 결과를 바꿀 수 있는 수정일 때만 영향을 받는 검사와 화면을 다시 확인한다.
