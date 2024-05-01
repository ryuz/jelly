#!/usr/bin/env python

import sys
import io
import re
import pandas as pd

def read_table(f):
    header = next(f).rstrip()
    separator = next(f).rstrip()
    data = []
    line = next(f).rstrip()
    while line != "":
        data.append(line)
        line = next(f).rstrip()

    # 区切り位置を検索
    seps = [0]
    for i in range(1, len(separator)):
        if separator[i-1] == ' ' and separator[i] == '-':
            seps.append(i)
    n = len(seps)

    # データを区切る
    headers = []
    datas  = [[] for _ in range(len(data))]
    for i in range(n):
        if i < n- 1:
            headers.append(header[seps[i]:seps[i+1]].strip())
            for j in range(len(data)):
                datas[j].append(data[j][seps[i]:seps[i+1]].strip())
        else:
            headers.append(header[seps[i]:].strip())
            for j in range(len(data)):
                datas[j].append(data[j][seps[i]:].strip())

    # データをDataFrameに変換
    return pd.DataFrame(datas, columns=headers)

def get_table(f, title):
    # タイトル行を検索
    line = next(f)
    while not line.startswith(f"| {title}"):
        line = next(f)
    # テーブルの先頭まで3行読み飛ばす
    next(f)
    next(f)
    next(f)
    return read_table(f)


def vivado_timing_rpt_to_csv(title, rpt_file, csv_file):
    with open(rpt_file, "r") as f:
        df = get_table(f, title)
    df.to_csv(csv_file, index=False)


if __name__ == "__main__":
    categorys = {
            "summary": "Clock Summary",
            "intra": "Intra Clock Table",
            "inter": "Inter Clock Table",
            "other": "Other Path Groups Table",
            "ignore": "User Ignored Path Table",
            "unconstrained": "Unconstrained Path Table",
        }
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <type> <rpt_file> <csv_file>")
        print(f"  [type] ")
        for t in categorys.keys():
            print(f"    {t} : {categorys[t]}")
        sys.exit(1)

    vivado_timing_rpt_to_csv(categorys[sys.argv[1]], sys.argv[2], sys.argv[3])
