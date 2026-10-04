# 영상 제작 규칙

이 문서는 사용자가 리포트용 영상을 요청했을 때만 읽고 적용한다. 영상 요청이 없으면 HyperFrames 사용량 조회, Gemini API 호출, 음성 생성과 렌더를 실행하지 않는다.

## 제작 경로

1. `/Users/mj/.agents/skills/hyperframes/SKILL.md`를 처음부터 끝까지 읽고 현재 요청을 해당 진입점의 상태·워크플로 표에 따라 라우팅한다. 새 영상이면 HyperFrames가 요구하는 사용량 확인과 intent 절차를 따르고, 기존 영상이면 요청한 편집·검증 범위만 수행한다.
2. 선택된 HyperFrames 워크플로와 필요한 domain skill을 해당 스킬의 지침대로 읽고 실행한다. 구성·타이밍은 `hyperframes-core`, 시각 설계는 `hyperframes-creative`, 검증·렌더는 `hyperframes-cli`가 맡는다.
3. 내레이션 생성은 `/Users/mj/.agents/skills/media-use/SKILL.md`와 그 스킬의 `references/audio.md`를 따른다. audio engine 요청에 `provider: "gemini"`를 지정하고, 사용자가 모델을 지정하지 않으면 media-use가 현재 지원하는 Gemini 기본 TTS 모델을 사용한다.
4. 생성한 음성과 음악을 HyperFrames composition에 배치한다. 배치된 트랙의 볼륨·EQ·automation·voiceover carve는 `/Users/mj/.agents/skills/hyperframes-audio/SKILL.md`가 맡는다. 음악이 음성 아래에서 재생되면 voiceover carve를 적용하고 `npx hyperframes check`로 작성된 chain과 automation을 확인한다.
5. HyperFrames의 preview·check·render 절차와 아래 검증을 통과한 최종 자산만 저장소에 넣고 문서에 배치한다.

## Gemini 인증

- 인증 파일은 `/Users/mj/.config/vibe-mjstudio/gemini.env`이고 환경 변수 이름은 `GEMINI_API_KEY`다.
- 실제 TTS 작업을 실행하는 프로세스에서만 이 파일을 환경으로 불러온다. 키 값을 명령 인자, 프롬프트, 로그, 코드, 문서, 커밋과 최종 보고에 쓰지 않는다.
- 인증 파일이나 키가 없으면 Gemini 호출을 실행하지 않고 인증이 필요하다고 보고한다. 키의 형식이나 값을 출력해 확인하지 않는다.

## 영상과 음성 검증

- 제작 언어는 사용자가 지정한 언어를 따르고, 미지정이면 한국어를 사용한다.
- 대본과 자막은 리포트와 원자료의 의미를 보존하고, 확인하지 않은 사실·수치·발언자를 추가하지 않는다.
- 실제로 생성된 음성의 처음·중간·끝과 문장 경계를 듣고 발음, 끊김, 화자, 목소리와 말투의 일관성을 확인한다.
- 자막과 장면 전환을 최종 음성의 실제 길이에 맞춘다. 임시 예상 길이로 렌더하지 않는다.
- 음성과 BGM이 함께 있으면 내레이션이 또렷하면서 BGM이 비어 보이지 않는지 렌더 결과를 듣는다. HyperFrames audio 지침에 따라 carve와 mix를 조정한다.
- 최종 영상의 길이, 해상도, 프레임 처음·중간·끝, 포스터, 재생 조작, 사이트의 실제 재생을 확인한다.
- 문서에서 영상의 `width`·`height` 또는 `aspect-ratio`를 고정해 모바일과 캐시 없는 첫 로드에서도 본문 위치가 밀리지 않게 한다.
- 사용한 Gemini 모델·목소리·언어·확인일을 기록하되 인증 정보는 기록하지 않는다.
