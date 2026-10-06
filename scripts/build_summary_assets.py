"""Build CSV and figures from the documented historical aggregate snapshot."""

import csv
import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter

ROOT = Path(__file__).resolve().parents[1]
SUMMARY = ROOT / "data" / "summary"
IMAGES = ROOT / "docs" / "images"
BLUE = "#3768B0"
TEAL = "#137C73"
INK = "#162D42"
MUTED = "#526678"


def label(value, digits=1):
    return f"{value:.{digits}f}".replace(".", ",") + "%"


def style_axis(ax, maximum):
    ax.set_ylim(0, maximum)
    ax.yaxis.set_major_formatter(PercentFormatter(xmax=100, decimals=0))
    ax.grid(axis="y", color="#DDE5EB", linewidth=0.7)
    ax.set_axisbelow(True)
    for side in ["top", "right", "left"]:
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_color("#DDE5EB")
    ax.tick_params(axis="both", length=0, labelcolor=INK, pad=10)


def finish(fig, filename, caption):
    fig.text(0.065, 0.045, caption, fontsize=10, color=MUTED, va="bottom")
    fig.savefig(IMAGES / filename, dpi=150, facecolor="white")
    plt.close(fig)


def export_csv(data):
    for key in ["assortment_actions", "discount_actions", "abc_revenue", "rfm_segments", "repeat_rate", "cohort_metrics"]:
        rows = data[key]
        with (SUMMARY / f"{key}.csv").open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)


def build_figures(data):
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 12, "text.color": INK, "axes.labelcolor": INK})
    rows = data["abc_revenue"]
    fig, ax = plt.subplots(figsize=(10.8, 6.3))
    fig.subplots_adjust(left=0.09, right=0.98, top=0.79, bottom=0.23)
    fig.text(0.065, 0.92, "Выручку формирует широкий ассортимент", fontsize=20, weight="bold")
    x = list(range(len(rows)))
    for offset, field, color, name, digits in [(-0.18, "sku_share_pct", BLUE, "Доля SKU", 2), (0.18, "revenue_share_pct", TEAL, "Доля выручки", 0)]:
        bars = ax.bar([i + offset for i in x], [r[field] for r in rows], width=0.34, color=color, label=name)
        ax.bar_label(bars, labels=[label(r[field], digits) for r in rows], padding=5, fontsize=12, color=INK)
    ax.set_xticks(x, [r["class"] for r in rows])
    style_axis(ax, 100)
    ax.legend(frameon=False, ncol=2, loc="upper center", bbox_to_anchor=(0.5, 1.17))
    finish(fig, "assortment-abc.png", "2023 год · 50 000 SKU · Сохранённые агрегаты; доли выручки приблизительны.\nИсточник: data/summary/summary.json")

    rows = data["rfm_segments"]
    fig, ax = plt.subplots(figsize=(10.8, 6.3))
    fig.subplots_adjust(left=0.09, right=0.98, top=0.79, bottom=0.26)
    fig.text(0.065, 0.92, "Размер и историческая ценность RFM-сегментов", fontsize=19, weight="bold")
    x = list(range(len(rows)))
    for offset, field, color, name in [(-0.18, "customer_share_pct", BLUE, "Доля клиентов"), (0.18, "revenue_share_pct", TEAL, "Доля выручки")]:
        bars = ax.bar([i + offset for i in x], [r[field] for r in rows], width=0.34, color=color, label=name)
        ax.bar_label(bars, labels=[label(r[field], 1) for r in rows], padding=5, fontsize=11, color=INK)
    ax.set_xticks(x, ["Перспективные", "Лучшие", "Ценные\nнеактивные", "Лояльные", "Спящие"], fontsize=10)
    style_axis(ax, 30)
    ax.legend(frameon=False, ncol=2, loc="upper center", bbox_to_anchor=(0.5, 1.18))
    finish(fig, "rfm-segments.png", "2023 год · Показаны пять из 11 сегментов; это не полное распределение.\nНа графике доли округлены до 0,1 п. п. · Источник: data/summary/summary.json")

    rows = data["repeat_rate"]
    fig, ax = plt.subplots(figsize=(10.8, 6.3))
    fig.subplots_adjust(left=0.09, right=0.98, top=0.81, bottom=0.25)
    fig.text(0.065, 0.92, "Повторная покупка в пределах окна", fontsize=20, weight="bold")
    x = list(range(len(rows)))
    bars = ax.bar(x, [r["repeat_rate_pct"] for r in rows], width=0.56, color=TEAL)
    ax.bar_label(bars, labels=[label(r["repeat_rate_pct"], 2) for r in rows], padding=6, fontsize=14, weight="bold", color=INK)
    ax.set_xticks(x, [f"{r['window_days']} дней\nN = {r['eligible_customers']:,}".replace(",", " ") for r in rows])
    style_axis(ax, 50)
    finish(fig, "repeat-rate.png", "2023 год · В каждом окне только клиенты с полным сроком наблюдения.\nЗнаменатели различаются. Повтор — покупка в другую дату. · Источник: data/summary/summary.json")


def main():
    data = json.loads((SUMMARY / "summary.json").read_text(encoding="utf-8"))
    IMAGES.mkdir(parents=True, exist_ok=True)
    export_csv(data)
    build_figures(data)
    print("Built 6 CSV files and 3 figures from the historical snapshot.")


if __name__ == "__main__":
    main()
