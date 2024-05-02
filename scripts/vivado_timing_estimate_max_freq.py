#!/usr/bin/env python

import sys
import math
import pandas as pd

def vivado_timing_estimate_max_freq(summary_csv, intra_csv, output_csv):
    df_summary = pd.read_csv(summary_csv, index_col=0)
    df_intra   = pd.read_csv(intra_csv, index_col=0)

    table = {
        "Clock": [],
        "Period(ns)": [],
        "Frequency(MHz)": [],
        "WNS(ns)": [],
        "Estimated Minimum Period(ns)": [],
        "Estimated Maximum Frequency(ns)": [],
    }

    for clk_name in df_intra.index:
        wns = df_intra.loc[clk_name, "WNS(ns)"]
        if not math.isnan(wns):
            period = df_summary.loc[clk_name, "Period(ns)"]
            freq   = df_summary.loc[clk_name, "Frequency(MHz)"]
            est_period = round(period - wns, 4)
            est_freq   = round(1000/est_period, 3)
            table["Clock"].append(clk_name)
            table["Period(ns)"].append(period)
            table["Frequency(MHz)"].append(freq)
            table["WNS(ns)"].append(wns)
            table["Estimated Minimum Period(ns)"].append(est_period)
            table["Estimated Maximum Frequency(ns)"].append(est_freq)
    df = pd.DataFrame(table)
    df.to_csv(output_csv, index=False)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <summary_csv> <intra_csv> <output_csv>")
        sys.exit(1)

    vivado_timing_estimate_max_freq(sys.argv[1], sys.argv[2], sys.argv[3])

