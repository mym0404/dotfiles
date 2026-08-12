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

첫 적용에서 Brewfile의 도구와 앱, Oh My Zsh, zsh-autosuggestions, mise 런타임, macOS 설정, Codex 사용자 플러그인을 순서대로 설치해요. Git 이름과 이메일은 초기화할 때 입력해요.

## 평소 사용법

```sh
chezmoi diff
chezmoi apply
chezmoi update
```

일반 파일은 대상 파일을 고친 뒤 `chezmoi add ~/.zshrc`처럼 소스에 반영하거나 `chezmoi edit --apply ~/.zshrc`로 바로 고쳐요.

Karabiner의 `karabiner.json`과 Codex의 `config.toml`은 일부 값만 관리해요. 이 두 파일에 `chezmoi add`를 실행하지 말고 chezmoi 소스의 `modify_` 파일과 `.chezmoitemplates`를 수정해요.

## 관리 범위

- 셸: zshenv, zprofile, zshrc, Oh My Zsh, zsh-autosuggestions
- 개발 도구: Git, mise, Neovim, lazygit, WezTerm, IdeaVim
- 앱: Karabiner-Elements, Zed, Codex 사용자 설정과 스킬
- 기타: lambda-gitster 테마, 에이전트 스킬, 사용자 폰트, macOS defaults

Codex 로그인·MCP·프로젝트 신뢰, Karabiner 장치 매핑, Dock 앱 배열, 디스플레이 배치와 macOS 권한은 각 Mac에 남겨요.
