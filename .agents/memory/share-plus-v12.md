---
name: share_plus 12.x API
description: share_plus 12.x deprecated the old Share.shareXFiles; documents the new SharePlus.instance.share() API
---

## Rule
Use `SharePlus.instance.share(ShareParams(...))` instead of the deprecated `Share.shareXFiles(...)`.

**Why:** share_plus 12.0.2 (used in this project) deprecates the static `Share` class methods. `flutter analyze` reports `deprecated_member_use` warnings which block zero-warning requirement.

**How to apply:**
```dart
import 'package:share_plus/share_plus.dart';

// OLD (deprecated):
await Share.shareXFiles([XFile(path)], subject: subject);

// NEW (correct):
await SharePlus.instance.share(
  ShareParams(files: [XFile(path)], subject: subject),
);
```
