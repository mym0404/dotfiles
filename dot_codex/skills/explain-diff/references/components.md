# Explain Diff Component Library

Copy these structures exactly. The template owns their CSS and responsive behavior. Never add component styles, substitute a generic card, nest bounded components, or use a component only for decoration.

Code-block controls are not a manually selectable component. Write only the `<pre data-code-source>` contract from [`notion-dark-theme.md`](notion-dark-theme.md); the renderer and fixed template create every filename header and compact WebStorm Open control.

## Contents

- [Selection](#selection)
- [Change marker](#change-marker)
- [Comparison table](#comparison-table)
- [Change flow](#change-flow)
- [Before and after](#before-and-after)
- [Rule list](#rule-list)
- [Concept card](#concept-card)
- [Callout](#callout)

## Selection

- Compare the same properties across several states or platforms with `comparison-table`.
- Show an ordered call or data path with `change-flow`.
- Show one state transition with `before-after`; use `comparison-table` when more than one property changes.
- Show independent conditions and outcomes with `rule-list`.
- Bound one self-contained toy example or concept with `concept-card`.
- Bound one definition, key condition, or material edge case with `callout`.

Use prose when none applies. Do not recreate a table with aligned `div` elements or recreate a list with a card grid.

## Change marker

Add `is-changed` only to an element whose represented code or behavior was added or changed in the inspected diff. Never mark an unchanged start point, end point, intermediate step, invariant, or conclusion merely to draw attention. Omit the class when the diff does not prove a change.

Keep compact flow labels and rule terms short enough for one line. Rewrite the label instead of shrinking, truncating, or inserting `<br>`. Explanatory values and card prose may wrap.

## Comparison table

```html
<div class="comparison-table">
  <table>
    <thead>
      <tr>
        <th scope="col">구간</th>
        <th scope="col">수정 전</th>
        <th scope="col">수정 후</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <th scope="row">공개 API</th>
        <td>Web 전용 중첩 값</td>
        <td class="is-changed">최상위 <code>nonce?</code></td>
      </tr>
      <tr>
        <th scope="row">네이티브 브리지</th>
        <td>인자 없음</td>
        <td class="is-changed">nullable 인자 전달</td>
      </tr>
    </tbody>
  </table>
</div>
```

## Change flow

```html
<ol class="change-flow">
  <li class="change-flow__step">
    <strong class="change-flow__title">앱 호출</strong>
    <span class="change-flow__value"><code>login(nonce)</code></span>
  </li>
  <li class="change-flow__step is-changed">
    <strong class="change-flow__title">JS 계약</strong>
    <span class="change-flow__value">인자 추가</span>
  </li>
  <li class="change-flow__step is-changed">
    <strong class="change-flow__title">Kakao SDK</strong>
    <span class="change-flow__value"><code>nonce</code> 전달</span>
  </li>
</ol>
```

## Before and after

```html
<div class="before-after">
  <article class="before-after__state">
    <span class="before-after__label">Before</span>
    <strong class="before-after__value"><code>web.nonce</code>만 사용</strong>
  </article>
  <span class="before-after__arrow">→</span>
  <article class="before-after__state is-changed">
    <span class="before-after__label">After</span>
    <strong class="before-after__value"><code>nonce</code> 우선</strong>
  </article>
</div>
```

## Rule list

```html
<dl class="rule-list">
  <div class="rule-list__row">
    <dt>추가 동의</dt>
    <dd><code>scopes</code>가 있으면 Account + scopes</dd>
  </div>
  <div class="rule-list__row is-changed">
    <dt>공통 조건</dt>
    <dd>선택된 모든 경로에 같은 <code>nonce</code> 전달</dd>
  </div>
</dl>
```

## Concept card

```html
<article class="concept-card">
  <span class="concept-card__eyebrow">Toy example</span>
  <h4 class="concept-card__title">하나의 값, 여러 경로</h4>
  <p class="concept-card__body">호출자가 준 <code>nonce</code>를 선택된 로그인 경로에 그대로 전달해요.</p>
</article>
```

## Callout

```html
<aside class="callout">
  <strong class="callout__title">핵심 조건</strong>
  <p class="callout__body">플랫폼 분기가 달라도 SDK가 받는 값은 같아야 해요.</p>
</aside>
```
