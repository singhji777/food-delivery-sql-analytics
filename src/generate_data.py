"""Builds a synthetic food-delivery database (SQLite) with 3 related tables:
customers, restaurants, orders  (calendar year 2025).

Planted patterns for the analysis to discover: lunch/dinner peaks, slower deliveries at peak,
cancellations rising with delivery time, channel quality differences, retention decay by cohort.
"""
import sqlite3, numpy as np, pandas as pd
from pathlib import Path

rng = np.random.default_rng(2025)
ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "data" / "food_delivery.db"

CITIES = ["Delhi", "Mumbai", "Bengaluru", "Hyderabad", "Pune", "Meerut"]
CITY_W = np.array([0.24, 0.24, 0.22, 0.14, 0.12, 0.04])
CITY_BASE_MIN = {"Delhi": 33, "Mumbai": 36, "Bengaluru": 38, "Hyderabad": 32, "Pune": 30, "Meerut": 27}
CUISINES = ["North Indian", "South Indian", "Chinese", "Biryani", "Pizza", "Burgers", "Desserts", "Healthy", "Street Food"]
CUISINE_PRICE = {"North Indian": 340, "South Indian": 220, "Chinese": 300, "Biryani": 380, "Pizza": 430,
                 "Burgers": 280, "Desserts": 210, "Healthy": 360, "Street Food": 170}
CHANNELS = ["Organic", "Paid Social", "Referral", "Google Ads", "Influencer"]
CH_P = [0.34, 0.26, 0.16, 0.16, 0.08]
CH_STICK = {"Organic": 1.0, "Paid Social": 0.65, "Referral": 1.45, "Google Ads": 0.85, "Influencer": 0.55}  # loyalty multiplier

# ---------- restaurants ----------
R = 220
restaurants = pd.DataFrame({
    "restaurant_id": np.arange(1, R + 1),
    "restaurant_name": [f"{rng.choice(['Spice','Urban','Royal','Tasty','Green','Golden','Desi','Metro','Royal','Smoky'])} "
                        f"{rng.choice(['Kitchen','Bites','Hub','Darbar','Corner','Express','Tadka','House'])} {i}" for i in range(1, R + 1)],
    "city": rng.choice(CITIES, R, p=CITY_W),
    "cuisine": rng.choice(CUISINES, R),
    "rating": np.clip(np.round(rng.normal(4.05, 0.4, R), 1), 2.8, 4.9),
    "is_cloud_kitchen": rng.choice([0, 1], R, p=[0.7, 0.3]),
})
restaurants["popularity"] = np.minimum(rng.pareto(2.2, R) + 1, 6)   # skewed (few restaurants dominate) but capped
restaurants["popularity"] *= np.where(restaurants.rating >= 4.2, 1.5, 1.0)

# ---------- customers ----------
C = 6000
month_w = np.array([5, 5, 6, 6, 7, 7, 8, 8, 9, 10, 10, 11], float); month_w /= month_w.sum()   # growing signups
signup_month = rng.choice(np.arange(1, 13), C, p=month_w)
signup_date = [pd.Timestamp(2025, m, 1) + pd.Timedelta(days=int(rng.integers(0, pd.Timestamp(2025, m, 1).days_in_month))) for m in signup_month]
customers = pd.DataFrame({
    "customer_id": np.arange(1, C + 1), "signup_date": signup_date,
    "city": rng.choice(CITIES, C, p=CITY_W), "acquisition_channel": rng.choice(CHANNELS, C, p=CH_P),
})
customers["lam"] = rng.gamma(1.0, 1.7, C) * customers.acquisition_channel.map(CH_STICK)

HOUR_W = np.array([1, .5, .3, .2, .2, .4, 1, 2, 3, 3, 4, 7, 11, 10, 6, 4, 4, 5, 8, 12, 12, 9, 5, 2], float); HOUR_W /= HOUR_W.sum()
END = pd.Timestamp("2025-12-31")
by_city = {c: restaurants[restaurants.city == c] for c in CITIES}

rows = []
for c in customers.itertuples():
    n = 1 + rng.poisson(c.lam * 2.2)
    span = (END - c.signup_date).days
    if span <= 0: n = 1
    # order timing: decays after signup (heavy in first weeks)
    later = rng.exponential(55, max(n - 1, 0)).astype(int)
    later = later[later <= span]                                    # drop orders that would fall after the data window
    offs = np.r_[int(rng.integers(0, min(3, max(span, 0)) + 1)), later].astype(int)   # first order within 3 days
    pool = by_city[c.city] if len(by_city[c.city]) else restaurants
    pw = (pool.popularity / pool.popularity.sum()).values
    for off in np.sort(offs):
        ts = c.signup_date + pd.Timedelta(days=int(off)) + pd.Timedelta(hours=int(rng.choice(24, p=HOUR_W)), minutes=int(rng.integers(0, 60)))
        r = pool.iloc[rng.choice(len(pool), p=pw)]
        items = int(rng.choice([1, 2, 3, 4, 5], p=[0.3, 0.32, 0.2, 0.12, 0.06]))
        value = float(np.round(CUISINE_PRICE[r.cuisine] * items * rng.uniform(0.8, 1.25), 0))
        disc = float(np.round(value * rng.choice([0, 0.1, 0.2, 0.3], p=[0.5, 0.25, 0.17, 0.08]), 0))
        peak = ts.hour in (12, 13, 19, 20, 21)
        mins = CITY_BASE_MIN[c.city] + (7 if peak else 0) + (4 if ts.dayofweek >= 5 else 0) + (-4 if r.is_cloud_kitchen else 0) + rng.gamma(2.0, 3.0)
        if ts.month in (7, 8): mins += 5                                   # monsoon
        mins = float(np.round(mins, 0))
        p_cancel = 0.025 + 0.004 * max(mins - 35, 0) + (0.01 if peak else 0)
        status = "Cancelled" if rng.random() < p_cancel else ("Refunded" if rng.random() < 0.012 else "Delivered")
        rows.append((ts, c.customer_id, int(r.restaurant_id), value, disc, float(rng.choice([0, 19, 29, 39], p=[0.2, 0.3, 0.3, 0.2])),
                     str(rng.choice(["UPI", "Card", "COD", "Wallet"], p=[0.55, 0.2, 0.15, 0.1])), status,
                     None if status == "Cancelled" else mins))

orders = pd.DataFrame(rows, columns=["order_ts", "customer_id", "restaurant_id", "order_value", "discount_amount",
                                     "delivery_fee", "payment_mode", "status", "delivery_minutes"])
orders = orders.sort_values("order_ts").reset_index(drop=True); orders.insert(0, "order_id", np.arange(10001, 10001 + len(orders)))
orders["order_ts"] = orders["order_ts"].dt.strftime("%Y-%m-%d %H:%M:%S")
customers["signup_date"] = pd.to_datetime(customers["signup_date"]).dt.strftime("%Y-%m-%d")

if DB.exists(): DB.unlink()
con = sqlite3.connect(DB)
con.executescript("""
CREATE TABLE customers  (customer_id INTEGER PRIMARY KEY, signup_date TEXT NOT NULL, city TEXT, acquisition_channel TEXT);
CREATE TABLE restaurants(restaurant_id INTEGER PRIMARY KEY, restaurant_name TEXT, city TEXT, cuisine TEXT, rating REAL, is_cloud_kitchen INTEGER);
CREATE TABLE orders (order_id INTEGER PRIMARY KEY, order_ts TEXT NOT NULL, customer_id INTEGER REFERENCES customers(customer_id),
                     restaurant_id INTEGER REFERENCES restaurants(restaurant_id), order_value REAL, discount_amount REAL,
                     delivery_fee REAL, payment_mode TEXT, status TEXT, delivery_minutes REAL);
""")
customers.drop(columns="lam").to_sql("customers", con, if_exists="append", index=False)
restaurants.drop(columns="popularity").to_sql("restaurants", con, if_exists="append", index=False)
orders.to_sql("orders", con, if_exists="append", index=False)
con.executescript("CREATE INDEX idx_orders_cust ON orders(customer_id); CREATE INDEX idx_orders_rest ON orders(restaurant_id); CREATE INDEX idx_orders_ts ON orders(order_ts);")
con.commit()
for t in ("customers", "restaurants", "orders"):
    print(t, con.execute(f"select count(*) from {t}").fetchone()[0])
print("sqlite version", sqlite3.sqlite_version)
con.close()
