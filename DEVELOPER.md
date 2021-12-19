# 開発者用メモ


## subtree 用設定

```
git remote add mem_access https://github.com/ryuz/jelly-mem_access.git
git subtree add --prefix=rust/mem_access --squash mem_access develop
```

```
subadd = "!f () { git subtree add --prefix=${1}  --squash ${2}  ${3} ;};f"
subpush = "!f () { git subtree push --prefix=${1}  --squash ${2}  ${3} ;};f"
subpull = "!f () { git subtree pull --prefix=${1}  --squash ${2}  ${3} ;};f"
```
