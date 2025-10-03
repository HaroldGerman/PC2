#!/usr/bin/env python3
import csv
from collections import Counter

INPUT = "out/normalized.csv"

def main():
    counts = Counter()
    try:
        with open(INPUT, newline="") as f:
            reader = csv.reader(f, delimiter=" ")
            for row in reader:
                if len(row) >= 5:
                    level = row[4]
                    counts[level] += 1
    except FileNotFoundError:
        print(f"Error: no existe {INPUT}")
        return

    print("Resumen de severidades:")
    for level, c in counts.items():
        print(f"{level}: {c}")

if __name__ == "__main__":
    main()
