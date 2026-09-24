---
name: rn-cdp
description: agent-device의 CDP 기능으로 RN·Expo의 Hermes 런타임을 디버깅한다. 네트워크 요청 실패·응답·지연, Runtime 객체·콘솔, JS 힙·CPU 진단에 사용한다. 일반 기기 조작과 React DevTools는 다루지 않는다.
---

# RN CDP

`agent-device cdp`가 제공하는 기능으로 RN 런타임의 문제를 재현하고 원인을 확인한다. 아래 명령 중 조사에 필요한 기능만 사용한다.

## 1. 대상 연결

실행 중인 개발 서버의 주소를 사용한다. 아래 `8081`은 기본값이다. 앱·기기·번들을 대조하고 CLI가 반환한 대상 ID를 선택한다. 같은 앱의 여러 런타임 중 첫 항목을 임의로 고르지 않는다.

```sh
agent-device cdp status
agent-device cdp target list --url http://localhost:8081
agent-device cdp target select <TARGET_ID>
agent-device cdp runtime eval --expr 'JSON.stringify({hermes:typeof HermesInternal!=="undefined",fabric:!!globalThis.nativeFabricUIManager})' --json
```

위 식은 런타임 특성만 확인하며 앱 식별이나 최신 번들을 증명하지 않는다. 필요하면 서버의 `/json/list` 메타데이터를 대조하되 선택에는 CLI의 ID를 쓴다. 앱 재시작·연결 종료 후에는 대상을 다시 조회한다.

`status`도 데몬을 시작할 수 있다. 같은 사용자 계정의 CDP 명령은 데몬과 선택 대상을 공유하므로 진행 중인 다른 작업의 대상을 바꾸지 않는다.

**완료:** 조사할 앱의 런타임을 식별하고 Runtime 응답을 확인한다.

## 2. 네트워크 요청 추적

선택한 런타임의 `Network.*` 이벤트를 수집한다. 다른 런타임이나 네이티브 계층의 요청까지 모두 보인다고 가정하지 않는다.

`target select`는 초기 네트워크 세션을 자동으로 만든다. `network status`와 `network sessions`로 확인하고 반환된 세션 ID를 고정해 조회한다. 자신이 만든 초기 세션은 그대로 사용할 수 있다. 다른 작업의 기록은 중단하지 않는다. 새 구간이 필요하면 자신의 기록만 `network stop`으로 마친 뒤 `network start --name repro`로 시작한다. 새 세션은 과거 요청을 가져오지 않는다.

```sh
agent-device cdp network status
agent-device cdp network sessions --limit 5
# 수집 시작 후 조사할 동작을 재현한다.
agent-device cdp network summary --session <SESSION_ID>
agent-device cdp network list --session <SESSION_ID> --text <ENDPOINT_FRAGMENT> --limit 10
agent-device cdp network request --session <SESSION_ID> --id <REQUEST_ID>
agent-device cdp network response-body --session <SESSION_ID> --id <REQUEST_ID>
```

- 실패는 전송 실패와 HTTP 오류를 구분한다. `network list --status failed`와 `--status 4xx` 또는 `--status 5xx`를 목적에 맞게 사용한다. 지연은 요청한 기준을 `--min-ms`로 지정하고 반복 호출·재시도도 확인한다.
- `network request`는 헤더와 본문을 생략한다. 필요한 필드만 `request-headers`, `response-headers`, `request-body`, `response-body`로 조회하며 같은 세션·요청 ID를 지정한다.
- body 조회는 런타임 지원과 연결 상태에 따라 실패할 수 있다. 조회 불가를 빈 응답으로 해석하지 않는다. 큰 본문·바이너리는 필요할 때만 `--file <ABSOLUTE_PATH>`로 저장한다. 보고할 때 인증값·쿠키 등 비밀값은 제외한다.
- `attached`나 0건만으로 수집 성공을 판단하지 않는다. 알려진 요청이 발생하는 재현 동작으로 수집 여부를 확인한다. RN 0.84 다중 host 환경에서 `Network.enable`이 `The Network domain is unavailable when multiple React Native hosts are registered.`로 실패한 사례가 있다. 이때 CDP로 수집하지 못한 범위와 오류를 보고한다. 진단을 위해 host 구조를 임의로 바꾸지 않는다.

**완료:** 재현 동작과 요청의 URL·method·status/오류·소요 시간, 필요한 응답 필드를 연결한다. 원인으로 단정할 근거가 없으면 관찰 사실과 추정을 구분한다. 요청 0건이면 지원·연결·수집 구간을 점검한 결과까지 남긴다.

## 3. Runtime 객체와 요소 조회 범위

Hermes CDP의 JS 객체는 화면 element나 React 컴포넌트 트리와 다르다. `document`·`DOM.*`·`Page.*` 지원을 전제로 요소를 찾지 않는다. CDP로 접근 가능한 객체가 있을 때만 속성을 조사하며, 객체를 찾지 못했다는 사실을 화면 요소 부재로 해석하지 않는다.

```sh
agent-device cdp runtime eval --expr '<KNOWN_OBJECT_EXPRESSION>' --json
agent-device cdp runtime props --id <OBJECT_ID> --own
agent-device cdp runtime release --id <OBJECT_ID>
```

소스나 실제 Runtime 응답에서 확인한 객체 경로를 사용한다. 응답에 object ID가 있으면 그 ID로 속성을 조회한다. 프레임워크 내부 전역 변수나 Fiber 경로를 추측해 화면 전체를 탐색하지 않는다. 조회한 속성을 실제 렌더 결과나 접근성 속성으로 단정하지 않는다.

필요한 값만 읽고 보존한 핸들은 해제한다. Promise 결과는 `runtime eval --await`로 기다린다. 보존한 핸들 자체가 객체를 붙잡아 누수 판단을 흐릴 수 있다. 상태를 바꾸는 식은 요청한 재현에 필요한 경우에만 실행한다.

**완료:** 조회한 객체 경로·속성·값을 근거로 남긴다. 필요한 요소 정보가 CDP에 노출되지 않으면 그 한계를 명시한다.

## 4. 콘솔

```sh
agent-device cdp console list --limit 10
agent-device cdp console get <MESSAGE_ID>
```

콘솔은 연결 중 수집한 범위이며 앱의 과거 로그 전체가 아니다.

## 5. JS 메모리

가벼운 샘플로 증가 여부를 확인하고, 동작 종료 후에도 남는 객체는 스냅샷으로 조사한다. 아래 자리표시자는 각 명령이 반환한 실제 ID로 바꾼다. 이름이나 순번을 ID로 추정하지 않는다.

```sh
agent-device cdp memory usage sample --label baseline
# 앱에서 조사할 동작을 실행하고 화면 닫기 등 정리 동작까지 완료한다.
agent-device cdp memory usage sample --label after-cleanup
agent-device cdp memory usage diff --base <BASE_SAMPLE_ID> --compare <AFTER_SAMPLE_ID>
```

누수 의심이 남으면 같은 동작과 정리 조건으로 다음 세 시점을 캡처한다.

```sh
agent-device cdp memory snapshot capture --name baseline --gc
# 조사할 동작을 실행한다.
agent-device cdp memory snapshot capture --name after-action --gc
# 화면 닫기 등 앱의 정리 동작을 실행한다.
agent-device cdp memory snapshot capture --name cleanup --gc
agent-device cdp memory snapshot leak-triplet --baseline <BASE_ID> --action <ACTION_ID> --cleanup <CLEANUP_ID> --limit 10
agent-device cdp memory snapshot classes --snapshot <CLEANUP_ID> --limit 10
agent-device cdp memory snapshot retainers --snapshot <CLEANUP_ID> --id <NODE_ID> --depth 8 --limit 10
```

- `--gc`는 강제 GC를 요청한다. 대상이 지원하는지 확인하고 비교 캡처의 GC 조건을 통일한다. 실패하면 성공한 것으로 처리하지 않는다.
- 한 번의 힙 증가나 `leak-signal`만으로 누수를 확정하지 않는다. 반복한 재현에서 정리 후에도 남는 객체와 보유 경로를 확인한다.
- JS heap usage, 스냅샷의 native 노드 포함 self 크기, retained 크기, 프로세스 RSS는 서로 다른 지표다. retained 크기는 공유 객체 때문에 단순 합산하면 중복될 수 있다.
- 원본이 필요할 때만 `capture --file <ABSOLUTE_PATH>`로 저장한다. 대형 스냅샷 전체를 대화에 출력하지 않고 요약과 필요한 객체만 조회한다.

## 6. JS CPU

```sh
agent-device cdp profile cpu status
agent-device cdp profile cpu start --name repro
# 시간을 제한해 조사할 동작을 재현한다.
agent-device cdp profile cpu stop
agent-device cdp profile cpu summary --session <SESSION_ID>
agent-device cdp profile cpu hotspots --session <SESSION_ID> --limit 10
agent-device cdp profile cpu source-maps --session <SESSION_ID>
```

이미 진행 중인 기록이 있으면 덮어쓰지 않는다. 기록 중 힙 스냅샷이나 강제 GC를 실행하면 측정에 섞이므로 별도로 조사한다. 소스맵이 없으면 원본 소스 위치까지 확인했다고 보고하지 않는다. JS CPU 결과만으로 네이티브 UI 스레드의 병목을 단정하지 않는다.

## Hermes에서 관찰한 제약

RN 0.84·Hermes와 내부 엔진 1.6.1에서 `Profiler.enable`은 미지원이어도 `Profiler.start/stop`은 성공했다. 메서드 하나의 실패로 CPU 기록 전체가 불가능하다고 단정하지 않는다. 힙 스냅샷 캡처 뒤 `HeapProfiler.disable`만 실패하면 캡처 결과와 정리 실패를 구분한다.

## 정리와 명령 확인

- 자신이 시작한 수집과 보존한 핸들을 정리한다. 작업 전용으로 시작한 데몬만 `agent-device cdp stop`으로 종료한다.
- 세부 문법은 `agent-device cdp skills get network` 또는 `agent-device cdp skills get runtime`으로 확인한다. 문서 경로 오류가 나면 [CDP 엔진 공식 문서](https://github.com/callstackincubator/agent-cdp)나 설치된 내부 패키지의 해당 문서를 읽는다. 문서의 명령도 위 실행 접두어를 사용한다.
