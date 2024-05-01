#!/usr/bin/env python

import sys
import io
import re
import pandas as pd


def read_utilization_table(f, category, pattern=None):
    """ utilization table を読み込む
    """

    try:
        if pattern is None:
            pattern = r"[0-9]+\. " + category
        
        # タイトルが出てくるまで読み飛ばす
        while True:
            line = next(f)
            if re.search(pattern, line):
                line = next(f)
                if line.startswith("----"):
                    break

        # 一文字目が + の行が出てくるまで読み飛ばす
        while not line.startswith("+"):
            line = next(f)
        # 一文字目が | の行が出てくるまで読み飛ばす
        while not line.startswith("|"):
            line = next(f)
        
        # タイトル行を "|" で区切ってリストにした後に各々の前後の空白を削除
        title = list(map(lambda x: x.strip(), line.split("|")[1:-1]))
        line = next(f)
        tables = {}
        for t in title:
            tables[t] = []

        # 区切り行を読み飛ばす
        while line.startswith("+"):
            line = next(f)
        
        # データ行を "|" で区切ってリストにした後に各々の前後の空白を削除
        while line.startswith("|"):
            data = line.split("|")[1:-1]
            data[0] = data[0].rstrip()[1:]
            data[1:] = list(map(lambda x: x.strip(), data[1:]))
            for i, t in enumerate(title):
                tables[t].append(data[i])

            line = next(f)
                # line の末尾の空白文字を削除

        df = pd.DataFrame(tables)
        df.insert(0, "Category", category)
        return df
    except StopIteration:
        return pd.DataFrame()


def vivado_utilization_placed_to_csv(rpt_file, csv_file):
    # ファイルを読み込む
    with open(rpt_file, 'r') as f:
        rpt = f.read()

    categorys = [
            "CLB Logic",
            "BLOCKRAM",
            "ARITHMETIC",
            "I/O",
            "CLOCK",
            "ADVANCED",
            "CONFIGURATION",
        ]
    # 章立てが変わる可能性があるので、毎回先頭からサーチする
    df = pd.concat([read_utilization_table(io.StringIO(rpt), c) for c in categorys])
    df.to_csv(csv_file, index=False)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <rpt_file> <csv_file>")
        sys.exit(1)

    vivado_utilization_placed_to_csv(sys.argv[1], sys.argv[2])


