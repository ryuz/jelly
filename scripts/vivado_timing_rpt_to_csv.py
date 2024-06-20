#!/usr/bin/env python

import sys
import re
import pandas as pd

def read_table(f):
    # ヘッダ読み込み(2文字以上の空白で区切る)
    headers = re.split(r'\s{2,}', next(f).strip())
    if len(headers) == 0:
        return None

    # テーブル準備
    tables = {}
    for header in headers:
        tables[header] = []

    # セパレータを読み飛ばす
    separeters = re.split(r'\s{2,}', next(f).strip())
    if len(separeters) != len(headers):
        return None

    # データ読み込み
    datas = re.split(r'\s{2,}', next(f).strip())
    while len(datas) == len(headers):
        for i, header in enumerate(headers):
            tables[header].append(datas[i])
        datas = re.split(r'\s{2,}', next(f).strip())

    # データをDataFrameに変換
    return pd.DataFrame(tables)


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
