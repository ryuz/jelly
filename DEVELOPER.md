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


## crates.io 登録用メモ

```
cargo login XXXXXX

cargo test

cargo package

cargo publish
```

