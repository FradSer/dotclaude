#!/usr/bin/env bash
#
# 同步脚本共享函数:上游快照。
#
# 问题:旧的 --check 比对「本地文件 vs 上游」。本地经 modifications 重放后必然与上游不同,
# 于是 --check 永远报「有更新」,无法区分「上游真有新东西」与「我们有本地改动」。
#
# 方案:每次同步保存一份「上游 sparse-checkout 树的哈希清单」快照。--check 比对
# 「当前上游 vs 上次同步快照」,全程不读本地文件,因此本地 modifications 不再造成假阳性。
#
# 快照存于 frontend/.sync-snapshots/<key>.manifest,随仓库提交(供任意 clone 共享基线)。
#

# 计算上游树的哈希清单(排除 .git),输出已排序的 "<sha>  ./relpath"
_snapshot_manifest() {
    local repo_dir="$1"
    [ -d "$repo_dir" ] || return 0
    ( cd "$repo_dir" 2>/dev/null && \
      find . -type f -not -path './.git/*' -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 shasum -a 256 2>/dev/null )
}

# snapshot_save <key> <repo_dir> <snapshot_dir>
# 保存当前上游树快照。失败不致命(调用方应 || true)。
snapshot_save() {
    local key="$1" repo_dir="$2" snap_dir="$3"
    [ -n "$key" ] && [ -d "$repo_dir" ] || return 0
    mkdir -p "$snap_dir"
    _snapshot_manifest "$repo_dir" > "$snap_dir/$key.manifest.tmp" 2>/dev/null \
        && mv "$snap_dir/$key.manifest.tmp" "$snap_dir/$key.manifest"
}

# snapshot_changed <key> <repo_dir> <snapshot_dir>
# 返回 0 = 上游较快照有变化(或无快照,保守视为有更新);返回 1 = 与快照一致(无更新)。
snapshot_changed() {
    local key="$1" repo_dir="$2" snap_dir="$3"
    local manifest="$snap_dir/$key.manifest"
    [ -f "$manifest" ] || return 0
    local current
    current=$(_snapshot_manifest "$repo_dir")
    [ "$current" = "$(cat "$manifest")" ] && return 1
    return 0
}

# snapshot_exists <key> <snapshot_dir>
snapshot_exists() {
    [ -f "$2/$1.manifest" ]
}
