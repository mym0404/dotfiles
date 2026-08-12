---
name: img
description: Prepare or publish a WebP image asset through the shared jsDelivr-backed repository, and use the resulting CDN URL when the requested output needs it.
---

# Img

## Workflow

1. Resolve the source branch:
   - Generate or edit an image with `$imagegen` when new visual work is requested.
   - Inspect the supplied local or generated image when publication is the only task.

Complete source selection when one final image path is chosen.

2. Resolve publication intent. A request for CDN hosting, upload, publication, or a jsDelivr URL authorizes the external GitHub write. A preview or draft request produces a local asset only.
3. Prepare a metadata-free WebP. Default to quality `82`; use `88` for text-heavy or detailed images, `76` for small low-detail thumbnails, and `--max-edge 2048` for large decorative images that need no original-resolution delivery.
4. For authorized publication, run:

```bash
python "${CODEX_HOME:-$HOME/.codex}/skills/img/scripts/prepare_webp.py" \
  --input <source-image> \
  --message "feat: add <short-name> image asset"
```

The helper requires ImageMagick `magick` and authenticated GitHub CLI `gh`. It converts the image, uploads it to `mym0404/ia2`, creates the commit, and prints the jsDelivr URL.

5. Verify the local file or published result. When the user requested the CDN URL inside another artifact or message, insert it only after the upload succeeds. Complete when the WebP exists, the repository path and CDN path match, an authorized upload reports a commit SHA, and any requested downstream use points to that exact URL.

## Publication Contract

- Upload directly through the helper or GitHub Contents API; keep repository cloning outside this flow.
- Use the repository default branch unless the user names another branch.
- Publish at the repository root with the helper's `YYYYMMDDHHMMSSNNN.webp` default.
- Use `--dest <name.webp>` only for an explicitly requested root filename.
- Use `--replace` only when the user explicitly intends to replace that exact asset.
- Keep the WebP as the single canonical published asset.

When direct `gh api` use is required, send `message`, base64 `content`, and `branch` to `/repos/mym0404/ia2/contents/<name.webp>`. Include `sha` only for an intentional replacement.

## Report

Return the useful result only:

- selected source path or generation mode
- published repository path when uploaded
- final CDN URL when uploaded
- commit SHA when created
