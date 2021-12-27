# 開発者用メモ(作者専用)


## subtree 用メモ

```
git remote add mem_access https://github.com/ryuz/jelly-mem_access.git --no-tags

git subtree split --prefix rust/mem_access --rejoin -b subtree/mem_access/develop
git push mem_access subtree/mem_access/develop:develop

git pull mem_access develop:subtree/mem_access/develop
git subtree merge --prefix rust/mem_access subtree/mem_access/develop



git remote add pac https://github.com/ryuz/jelly-pac.git --no-tags


```



## subtree 用メモ(旧)

リモートリポジトリ登録

```
git remote add mem_access https://github.com/ryuz/jelly-mem_access.git
git subtree add --prefix=rust/mem_access --squash mem_access develop
```

リモートリポジトリ操作

```
git subtree add  --prefix=<prefix> --squash <repository> <refspec>
git subtree push --prefix=<prefix> --squash <repository> <refspec>
git subtree pull --prefix=<prefix> --squash <repository> <refspec>
```


```
subadd = "!f () { git subtree add --prefix=${1}  --squash ${2}  ${3} ;};f"
subpush = "!f () { git subtree push --prefix=${1}  --squash ${2}  ${3} ;};f"
subpull = "!f () { git subtree pull --prefix=${1}  --squash ${2}  ${3} ;};f"
```
