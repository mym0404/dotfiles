# dotfiles

Apple Silicon Mac의 셸, 개발 도구, 앱 설정과 일부 macOS 설정을 chezmoi로 관리해요.

## 새 Mac 설정

1. Homebrew를 설치해요.

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. chezmoi와 GitHub CLI를 설치하고 로그인해요.

   ```sh
   brew install chezmoi gh
   gh auth login
   gh auth setup-git
   ```

3. 비공개 저장소를 받아 적용해요.

   ```sh
   chezmoi init --apply mym0404/dotfiles
   ```

4. 개인 `MJ` 플러그인을 활성화해요.

   ```sh
   codex plugin add mj@personal
   ```

   `~/plugins/mj`와 개인 마켓플레이스는 chezmoi가 복원하지만, 플러그인 설치 상태는 Mac마다 따로 관리해요.

첫 적용에서 Brewfile의 도구와 앱, Oh My Zsh, zsh-autosuggestions, mise 런타임, macOS 설정, Codex 사용자 플러그인을 순서대로 설치해요. Git 이름과 이메일은 초기화할 때 입력해요.

## 평소 사용법

```sh
csync
chezmoi diff
chezmoi apply
chezmoi update
```

`csync`는 관리 중인 폴더의 새 파일과 일반 파일의 수정을 소스에 반영하고, 로컬에서 삭제한 항목은 소스에서도 제거해요. 변경 사항을 커밋한 뒤 원격 변경을 받아 푸시하고 로컬에 적용해요. 스킬을 새로 만들 때마다 `chezmoi add`를 실행할 필요는 없어요.

새 앱의 설정 폴더처럼 아직 관리하지 않는 경로는 처음 한 번 `chezmoi add ~/.config/앱이름`으로 등록해요. 이후 해당 폴더 안의 추가·수정·삭제는 `csync`가 반영해요. `.codex`, `.config`, `.oh-my-zsh`, `Library` 바로 아래의 미등록 항목은 자동으로 수집하지 않아요. 브라우저 세션, 설치된 Oh My Zsh 플러그인, Git 내부 파일, 의존성과 캐시는 제외해요.

템플릿 파일은 chezmoi 소스를 수정하거나 `chezmoi edit`로 고쳐요. `csync`는 로컬에서 렌더링한 값으로 템플릿을 덮어쓰지 않고, 마지막 적용 단계에서 템플릿과 일부 값만 관리하는 파일은 소스의 규칙을 확인 질문 없이 적용해요.

Karabiner의 `karabiner.json`과 Codex의 `config.toml`은 일부 값만 관리해요. 이 두 파일에 `chezmoi add`를 실행하지 말고 chezmoi 소스의 `modify_` 파일과 `.chezmoitemplates`를 수정해요.

## 관리 범위

- 셸: zshenv, zprofile, zshrc, Oh My Zsh, zsh-autosuggestions
- 개발 도구: Git, mise, Neovim, lazygit, WezTerm, IdeaVim
- 앱: Karabiner-Elements, Zed, Codex 사용자 설정과 스킬
- 기타: lambda-gitster 테마, 에이전트 스킬, 사용자 폰트, macOS defaults

Codex 로그인·MCP·프로젝트 신뢰, Karabiner 장치 매핑, Dock 앱 배열, 디스플레이 배치와 macOS 권한은 각 Mac에 남겨요.
